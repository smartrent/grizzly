defmodule Grizzly.FirmwareUpdates.OTWUpdateRunner do
  @moduledoc """
  State machine for managing an OTW update for a Z-Wave controller module.

  Only 700-series and later modules are supported.

  ## State Diagram

  ```mermaid
  stateDiagram-v2
    [*] --> startup_delay
    startup_delay --> run_prechecks: delay complete
    run_prechecks --> [*]: no update needed
    run_prechecks --> init: update available
    state if_init <<choice>>
    init --> if_init
    if_init --> reboot_to_bootloader: prechecks ok
    if_init --> detect_bootloader_menu: prechecks failed
    reboot_to_bootloader --> detect_bootloader_menu: menu detected
    detect_bootloader_menu --> [*]: menu not detected
    detect_bootloader_menu --> uploading
    state uploading_if <<choice>>
    uploading --> uploading_if
    uploading_if --> upload_complete: success
    uploading_if --> run_prechecks: first timeout
    uploading_if --> [*]: second timeout
    upload_complete --> [*]
  ```
  """

  @behaviour :gen_statem

  alias Grizzly.FirmwareUpdates.OTW.UpdateSpec
  alias Grizzly.ZWave.Command

  require Logger

  @in_progress_alarm Grizzly.FirmwareUpdates.OTWUpdateInProgress
  @error_alarm Grizzly.FirmwareUpdates.OTWUpdateFailedWhileInProgress

  # Time to wait after stopping Z/IP Gateway before trying to open the serial port
  # (to ensure it's actually stopped and the serial port can be re-opened).
  @zipgateway_shutdown_delay 500

  # Time to wait when detecting the bootloader menu before trying something to
  # get it to show up.
  @detect_bootloader_menu_timeout :timer.seconds(1)

  @typedoc """
  The various status of a firmware update of the Z-Wave module

  * `:started` - the firmware update has been initiated and all validation of
    the firmware update is complete.
  * `{:done, :success}` - the firmware update of the Z-Wave module is successful.
  * `{:done, :skipped}` - no firmware update was applied.
  * `{:error, reason}` - A firmware update of the Z-Wave module was attempted
    but failed for some `reason`.
  """
  @type update_status :: :started | {:done, :success | :skipped} | {:error, atom()}

  @type state ::
          :startup_delay
          | :run_prechecks
          | :init
          | :reboot_to_bootloader
          | :detect_bootloader_menu
          | :uploading
          | :upload_complete
          | :done

  @options_schema NimbleOptions.new!(
                    serial_port: [
                      type: :string,
                      doc: "The path to serial port where the Z-Wave module is connected.",
                      required: true
                    ],
                    startup_delay: [
                      type: :non_neg_integer,
                      default: :timer.minutes(1),
                      doc:
                        "Time to wait after starting the runner before beginning the update process."
                    ],
                    upload_timeout: [
                      type: :timeout,
                      default: :timer.seconds(90),
                      doc: "Timeout for the GBL upload."
                    ],
                    update_specs: [
                      type: {:list, {:struct, Grizzly.FirmwareUpdates.OTW.UpdateSpec}},
                      default: [],
                      doc: """
                      A list of `Grizzly.FirmwareUpdates.OTW.UpdateSpec` structs that define the
                      available firmware updates.
                      """
                    ],
                    module_reset_fun: [
                      type: {:or, [:mfa, {:fun, 0}]},
                      doc: """
                      A function that performs a hard reset of the Z-Wave module, typically via GPIO
                      or power cycle. If not provided, recovering from a failed upload may not work
                      as expected.
                      """
                    ]
                  )

  @typedoc """
  Options for configuring the OTW update runner.

  ## Options

  #{NimbleOptions.docs(@options_schema)}
  """
  @type start_opt() :: unquote(NimbleOptions.option_typespec(@options_schema))

  @typep state_data :: %{
           serial_port: String.t(),
           module_reset_fun: (-> :ok) | nil,
           update_specs: [UpdateSpec.t()],
           exmodem: GenServer.server() | nil,
           uart: GenServer.server() | nil,
           startup_delay: non_neg_integer(),
           upload_timeout: timeout(),
           spec: UpdateSpec.t() | nil,
           zgw_version_check_failed: boolean(),
           upload_failures: non_neg_integer(),
           errors: non_neg_integer(),
           result:
             :no_update_needed
             | :bootloader_menu_not_detected
             | :failed_to_open_serial_port
             | :update_successful
             | nil
         }

  @doc """
  Returns a specification to start this module under a supervisor.

  See `Supervisor`.
  """
  @spec child_spec(args :: keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end

  @doc """
  Start the OTW update runner.

  See `t:start_opt/0` for available options.
  """
  @spec start_link([start_opt()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options_schema)

    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, opts,
      hibernate_after: :timer.minutes(1)
    )
  end

  @doc """
  Returns true if an OTW update is in progress (the state is not `:startup_delay`
  or `:done`).
  """
  @spec busy?() :: boolean()
  def busy?() do
    get_state() not in [:startup_delay, :run_prechecks, :done]
  end

  @doc """
  Gets the current state of the OTW update runner process. Returns nil if the
  process is not started.
  """
  @spec get_state() :: state() | nil
  def get_state() do
    :gen_statem.call(__MODULE__, :get_state)
  catch
    :exit, {:noproc, _} -> nil
  end

  @impl :gen_statem
  def init(opts) do
    Process.flag(:trap_exit, true)

    update_specs =
      opts
      |> Keyword.get(:update_specs, [])
      |> Enum.map(fn
        spec when not is_struct(spec, UpdateSpec) -> struct(UpdateSpec, spec)
        spec -> spec
      end)
      |> Enum.sort_by(& &1.version, {:desc, Version})

    data = %{
      serial_port: Keyword.fetch!(opts, :serial_port),
      module_reset_fun: Keyword.get(opts, :module_reset_fun),
      update_specs: update_specs,
      exmodem: nil,
      uart: nil,
      startup_delay: Keyword.get(opts, :startup_delay, :timer.minutes(1)),
      upload_timeout: Keyword.get(opts, :upload_timeout, :timer.seconds(90)),
      spec: nil,
      zgw_version_check_failed: false,
      upload_failures: 0,
      errors: 0,
      result: nil
    }

    if data.update_specs == [] do
      :ignore
    else
      {:ok, :startup_delay, data, []}
    end
  end

  @impl :gen_statem
  def callback_mode(), do: [:handle_event_function, :state_enter]

  @impl :gen_statem
  def terminate(_reason, _state, data) do
    cleanup(data)
  end

  @impl :gen_statem

  #
  # STATE ENTER CALLBACKS
  #

  # Whenever we enter the startup_delay state, set a state timeout equal to the
  # configured delay.
  def handle_event(:enter, old_state, :startup_delay, data) do
    log_state_change(old_state, :startup_delay)
    data = %{data | errors: 0}

    {:next_state, :startup_delay, data, [{:state_timeout, data.startup_delay, :delay_complete}]}
  end

  def handle_event(:enter, old_state, :run_prechecks, _data) do
    log_state_change(old_state, :run_prechecks)
    :keep_state_and_data
  end

  # Don't reset errors when repeating the detect_bootloader_menu state
  def handle_event(:enter, :detect_bootloader_menu, :detect_bootloader_menu, data) do
    log_state_change(:detect_bootloader_menu, :detect_bootloader_menu)

    {:next_state, :detect_bootloader_menu, data,
     [{:state_timeout, @detect_bootloader_menu_timeout, :timeout}]}
  end

  def handle_event(:enter, old_state, :detect_bootloader_menu, data) do
    log_state_change(old_state, :detect_bootloader_menu)
    data = %{data | errors: 0}

    {:next_state, :detect_bootloader_menu, data,
     [{:state_timeout, @detect_bootloader_menu_timeout, :timeout}]}
  end

  # When entering the uploading state, we need to:
  #   * set an alarm to indicate that a firmware update is in progress
  #   * set a state timeout to abort if the upload takes too long
  def handle_event(:enter, old_state, :uploading, data) do
    log_state_change(old_state, :uploading)

    gbl = File.read!(data.spec.path)
    {:ok, exmodem} = Exmodem.start_link(gbl)

    data = %{data | errors: 0, exmodem: exmodem}

    if data.upload_timeout == :infinity do
      {:next_state, :uploading, data}
    else
      {:next_state, :uploading, data, [{:state_timeout, data.upload_timeout, :upload_timeout}]}
    end
  end

  # When the upload is complete, we should get dumped back to the bootloader
  # prompt. If that doesn't happen soon enough, reset the module and continue.
  def handle_event(:enter, old_state, :upload_complete, data) do
    log_state_change(old_state, :upload_complete)
    :alarm_handler.clear_alarm(@in_progress_alarm)

    {:next_state, :upload_complete, data, [{:state_timeout, :timer.seconds(5), :timeout}]}
  end

  def handle_event(:enter, old_state, :done, data) do
    :alarm_handler.clear_alarm(@in_progress_alarm)
    log_state_change(old_state, :done)
    data = cleanup(data)

    case data.result do
      :no_upgrade_needed -> report_status({:done, :skipped})
      :update_successful -> report_status({:done, :success})
      other -> report_status({:error, other})
    end

    {:next_state, :done, data, []}
  end

  # Reset error count on any other state change.
  def handle_event(:enter, old_state, new_state, data) do
    log_state_change(old_state, new_state)
    {:next_state, new_state, %{data | errors: 0}}
  end

  #
  # EVENT HANDLER CALLBACKS
  #

  # The startup delay is finished. Now go to run_prechecks.
  def handle_event(:state_timeout, :delay_complete, :startup_delay, data) do
    {:next_state, :run_prechecks, data, [next_event_action(:zgw_version_check)]}
  end

  # Query Z/IP Gateway for the current Z-Wave module version and see if we have
  # an update to run. If we're unable to get an answer from Z/IP Gateway, we'll
  # increment the error count and repeat this event after a short delay, up to 3
  # attempts. If we exceed the max attempts, we'll continue on to try to detect
  # the Gecko bootloader and upload the firmware with the highest version --
  # after all, some firmware is better than none firmware.
  #
  # If we run into an error like :including or :firmware_updating when trying to
  # get the version, we should delay and try again (these don't count toward the
  # max attempts to get the version).
  def handle_event(:internal, :zgw_version_check, :run_prechecks, %{errors: errors} = data)
      when errors < 3 do
    case version_from_zipgateway() do
      {:ok, version} ->
        Logger.info("[Grizzly] Detected Z-Wave module version: #{version}")
        # If we got a version, we can check if we need to update.
        case Enum.find(data.update_specs, &UpdateSpec.applies?(&1, version)) do
          nil ->
            {:next_state, :done, %{data | errors: 0, result: :no_update_needed}}

          spec ->
            {:next_state, :init, %{data | errors: 0, spec: spec},
             [next_event_action(:stop_zipgateway)]}
        end

      {:error, reason} when reason in [:including, :firmware_updating] ->
        {:keep_state, %{data | errors: 0},
         [next_event_action(:zgw_version_check, :timer.seconds(30))]}

      {:error, _reason} ->
        {:keep_state, %{data | errors: data.errors + 1},
         [next_event_action(:zgw_version_check, :timer.seconds(5))]}
    end
  end

  # Exceeded max attempts to get the Z-Wave module version from Z/IP Gateway.
  # Proceed to open the serial port and try to detect the bootloader. From here,
  # we assume that the firmware with the highest version should be uploaded.
  def handle_event(:internal, :zgw_version_check, :run_prechecks, %{errors: errors} = data)
      when errors >= 3 do
    data = %{data | spec: hd(data.update_specs), zgw_version_check_failed: true}
    {:next_state, :init, data, [next_event_action(:stop_zipgateway)]}
  end

  def handle_event(:internal, :stop_zipgateway, :init, _data) do
    :alarm_handler.set_alarm({@in_progress_alarm, []})
    report_status(:started)
    stop_zipgateway()
    {:keep_state_and_data, [next_event_action(:open_serial_port, @zipgateway_shutdown_delay)]}
  end

  def handle_event(:internal, :open_serial_port, :init, %{errors: errors} = data)
      when errors < 3 do
    case open_uart(data.serial_port) do
      {:ok, uart} ->
        _ = module_reset(data)

        if data.zgw_version_check_failed do
          Logger.info("[Grizzly] ZGW version check failed; resetting module before proceeding")
          {:next_state, :detect_bootloader_menu, %{data | uart: uart}}
        else
          {:next_state, :reboot_to_bootloader, %{data | uart: uart}, next_event_action(:send)}
        end

      {:error, reason} ->
        Logger.error(
          "[Grizzly] Failed to open serial port #{data.serial_port}: #{inspect(reason)}"
        )

        {:keep_state, %{data | errors: data.errors + 1}}
    end
  end

  # If we fail to open the serial port after 3 attempts, fail the update.
  def handle_event(:internal, :open_serial_port, :init, %{errors: errors} = data)
      when errors >= 3 do
    {:next_state, :done, %{data | result: :failed_to_open_serial_port}}
  end

  def handle_event(:internal, :send, :reboot_to_bootloader, data) do
    Logger.info("[Grizzly] Rebooting Z-Wave module to bootloader")
    :ok = Circuits.UART.write(data.uart, <<0x06, 0x01, 0x03, 0x00, 0x27, 0xDB>>)

    {:next_state, :detect_bootloader_menu, data}
  end

  # If we haven't received the bootloader prompt yet, send a null byte to try to
  # get it to appear.
  def handle_event(:state_timeout, :timeout, :detect_bootloader_menu, %{errors: errors} = data)
      when errors < 3 do
    :ok = Circuits.UART.write(data.uart, <<0x00>>)
    {:repeat_state, %{data | errors: errors + 1}}
  end

  def handle_event(:state_timeout, :timeout, :detect_bootloader_menu, %{errors: errors} = data)
      when errors >= 3 do
    {:next_state, :done, %{data | result: :bootloader_menu_not_detected}}
  end

  # This is a generic handler for setting the next event after a timeout. It can be
  # used to repeat events after a delay.
  def handle_event({:timeout, :next_event}, {event_type, event_content}, state, _data) do
    Logger.info(
      "[Grizzly] Delay complete, sending next event #{inspect(event_type)}, #{inspect(event_content)} (state: #{inspect(state)})"
    )

    {:keep_state_and_data, [{:next_event, event_type, event_content}]}
  end

  #
  # API CALLBACKS (call/cast/info)
  #

  # Ignore UART messages in other states
  def handle_event(:info, {:circuits_uart, _port, data}, :init, data) do
    :keep_state_and_data
  end

  # This is probably the ACK from the reboot to bootloader command.
  def handle_event(:info, {:circuits_uart, _port, <<0x06>>}, :detect_bootloader_menu, _data) do
    :keep_state_and_data
  end

  # We have the bootloader menu. Send "1" to start the upload.
  def handle_event(
        :info,
        {:circuits_uart, _port, <<"\r\nGecko", _::binary>>},
        :detect_bootloader_menu,
        data
      ) do
    Process.sleep(10)
    :ok = Circuits.UART.write(data.uart, "1\n")
    :ok = Circuits.UART.drain(data.uart)
    {:next_state, :uploading, data, []}
  end

  # Discard other UART data in detect_bootloader_menu state. It's probably SAPI commands,
  # so send an ACK and another reboot command to keep things moving.
  def handle_event(:info, {:circuits_uart, _port, _uart_data}, :detect_bootloader_menu, data) do
    :ok = Circuits.UART.write(data.uart, <<0x06, 0x01, 0x03, 0x00, 0x27, 0xDB>>)
    :ok = Circuits.UART.drain(data.uart)
    :keep_state_and_data
  end

  # Ignore the "begin upload" message in uploading state
  def handle_event(:info, {:circuits_uart, _port, "\r\nbegin upload\r\n"}, :uploading, _data) do
    :keep_state_and_data
  end

  # Receive data from UART in uploading state
  def handle_event(:info, {:circuits_uart, _port, uart_data}, :uploading, data) do
    case Exmodem.receive_data(data.exmodem, uart_data) do
      # When Exmodem tells us to send an ETB (end of transmission block), do so.
      # However, instead of sending an ACK back, the Gecko bootloader will print
      # "Serial upload complete" and then return to the bootloader prompt. At this
      # point, we can stop the Exmodem process.
      {:send, <<0x17>>} ->
        Exmodem.stop(data.exmodem)
        :ok = Circuits.UART.write(data.uart, <<0x17>>)
        {:next_state, :upload_complete, %{data | exmodem: nil}, []}

      {:send, to_send} ->
        {sent, total} = Exmodem.progress(data.exmodem)

        if rem(sent, div(total, 10)) == 0 do
          Logger.info("[Grizzly] OTW update progress: #{sent}/#{total} packets sent")
        end

        :ok = Circuits.UART.write(data.uart, to_send)
        :keep_state_and_data

      :ignore ->
        :keep_state_and_data

      {:error, :canceled_by_receiver} ->
        Logger.error("[Grizzly] Firmware upload canceled by receiver")
        _ = module_reset(data)

        {:next_state, :done, %{data | result: :update_rejected_by_zwave_module}}

      {:error, :unexpected_data} ->
        Logger.error(
          "[Grizzly] Exmodem received unexpected data during upload: #{inspect(uart_data, limit: :infinity)}"
        )

        :keep_state_and_data
    end
  end

  # If the upload times out, clean up and try again from the top ONCE.
  def handle_event(:state_timeout, :upload_timeout, :uploading, data) do
    data = cleanup(data)
    _ = module_reset(data)

    :alarm_handler.set_alarm({@error_alarm, []})

    if data.upload_failures < 1 do
      Logger.warning(
        "[Grizzly] OTW update timed out while in uploading state. Trying one more time from the top."
      )

      {:next_state, :run_prechecks,
       %{
         data
         | errors: 0,
           zgw_version_check_failed: false,
           upload_failures: data.upload_failures + 1
       }, [next_event_action(:zgw_version_check)]}
    else
      Logger.error(
        "[Grizzly] OTW update timed out again while in uploading state. Failing the update."
      )

      {:next_state, :done, %{data | result: :update_failed, exmodem: nil}}
    end
  end

  # Exmodem hits a receiver timeout and exits during upload
  def handle_event(:info, {:EXIT, pid, :timeout}, :uploading, %{exmodem: pid} = data) do
    handle_event(:state_timeout, :upload_timeout, :uploading, data)
  end

  # Got data in upload complete state. We're probably back at the bootloader prompt.
  def handle_event(:info, {:circuits_uart, _port, uart_data}, :upload_complete, data) do
    if String.contains?(uart_data, " > ") do
      # Once the prompt is done printing, send "2" to reboot the module into the
      # application.
      :ok = Circuits.UART.write(data.uart, "2\n")
      :ok = close_uart(data.uart)

      {:next_state, :done, %{data | result: :update_successful, uart: nil}}
    else
      # If we get anything else, just wait for the prompt. If we don't get it, the
      # state timeout will help us out.
      {:keep_state_and_data, []}
    end
  end

  def handle_event(:state_timeout, :timeout, :upload_complete, data) do
    :ok = Circuits.UART.write(data.uart, "2\n")
    :ok = close_uart(data.uart)

    _ = module_reset(data)
    {:next_state, :done, %{data | result: :update_successful, uart: nil}}
  end

  def handle_event(:info, {:circuits_uart, _port, uart_data}, state, _data) do
    Logger.debug(
      "[Grizzly] Discarding UART data received while in #{inspect(state)} state: #{inspect(uart_data)}"
    )

    :keep_state_and_data
  end

  def handle_event(:info, {:EXIT, _pid, _reason}, _state, _data) do
    :keep_state_and_data
  end

  def handle_event({:call, from}, :get_state, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  @spec version_from_zipgateway() ::
          {:ok, Version.version()} | {:error, Grizzly.send_command_error()}
  defp version_from_zipgateway() do
    case Grizzly.send_command(1, :version_zwave_software_get) do
      {:ok, %{command: %Command{} = cmd}} -> {:ok, Command.param!(cmd, :host_interface_version)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp cleanup(data) do
    if is_pid(data.uart) && Process.alive?(data.uart) do
      :ok = Circuits.UART.close(data.uart)
      :ok = Circuits.UART.stop(data.uart)
    end

    if is_pid(data.exmodem) && Process.alive?(data.exmodem) do
      :ok = Exmodem.stop(data.exmodem)
    end

    if data.result in [:update_successful, :no_upgrade_needed] do
      :alarm_handler.clear_alarm(@error_alarm)
    end

    :alarm_handler.clear_alarm(@in_progress_alarm)
    _ = start_zipgateway()

    %{data | uart: nil, exmodem: nil}
  end

  defp open_uart(serial_port) do
    with {:ok, uart} <- Circuits.UART.start_link(),
         :ok <-
           Circuits.UART.open(uart, serial_port,
             speed: 115_200,
             active: true,
             framing: Grizzly.FirmwareUpdates.OTW.BootloaderFraming
           ) do
      {:ok, uart}
    end
  end

  @spec module_reset(state_data()) :: :ok
  defp module_reset(%{module_reset_fun: fun}) when is_function(fun, 0), do: fun.()
  defp module_reset(%{module_reset_fun: {m, f, a}}), do: apply(m, f, a)
  defp module_reset(_), do: :ok

  defp log_state_change(old_state, new_state) do
    Logger.debug(
      "[Grizzly] OTW Update Runner state change: #{inspect(old_state)} -> #{inspect(new_state)}"
    )
  end

  @spec next_event_action(term(), timeout(), :gen_statem.event_type()) :: :gen_statem.action()
  defp next_event_action(event_content, timeout \\ 0, event_type \\ :internal) do
    if timeout == 0 do
      {:next_event, event_type, event_content}
    else
      {{:timeout, :next_event}, timeout, {event_type, event_content}}
    end
  end

  defp start_zipgateway() do
    Grizzly.start_zipgateway()
  catch
    # Supervisor probably wasn't running
    :exit, {:noproc, _} ->
      :ok
  end

  defp stop_zipgateway() do
    Grizzly.stop_zipgateway()
  catch
    # Supervisor probably wasn't running
    :exit, {:noproc, _} ->
      :ok
  end

  @spec report_status(update_status()) :: :ok
  defp report_status(status) do
    Grizzly.Events.broadcast_event(:otw_firmware_update, status)
    :ok
  end

  defp close_uart(uart) do
    :ok = Circuits.UART.drain(uart)
    :ok = Circuits.UART.close(uart)
    :ok = Circuits.UART.stop(uart)
  end
end
