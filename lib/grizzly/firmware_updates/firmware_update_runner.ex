defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunner do
  @moduledoc false
  use GenServer

  alias Grizzly.{Connection, FirmwareUpdates, Options, Report}
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner.{FirmwareUpdate, Image}
  alias Grizzly.Connections.AsyncConnection
  require Logger

  @typedoc """
  At any given moment there can only be 1 `FirmwareUpdateRunner` process going so
  this process is the name of this module.

  However, all the functions in this module can take the pid of the process or
  the name to aid in the flexibility of the calling context.
  """

  @type t :: pid() | __MODULE__

  @default_fragment_size 1024

  def child_spec(opts) do
    # Don't restart the firmware update if there is a failure
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  @spec start_link(Options.t(), [FirmwareUpdates.opt()]) :: GenServer.on_start()
  def start_link(_grizzly_options, opts \\ []) do
    # ensure that manufacturer id is in the opts - probably should do better validation
    _ = Keyword.fetch!(opts, :manufacturer_id)

    default_opts = [
      handler: self(),
      device_id: 1,
      firmware_id: 0,
      hardware_version: 0,
      firmware_target: 0,
      max_fragment_size: @default_fragment_size,
      activation_may_be_delayed?: false
    ]

    GenServer.start_link(
      __MODULE__,
      Keyword.merge(default_opts, opts),
      name: __MODULE__
    )
  end

  @impl true
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    device_id = Keyword.fetch!(opts, :device_id)
    manufacturer_id = Keyword.fetch!(opts, :manufacturer_id)
    firmware_id = Keyword.fetch!(opts, :firmware_id)
    hardware_version = Keyword.fetch!(opts, :hardware_version)
    firmware_target = Keyword.fetch!(opts, :firmware_target)
    max_fragment_size = Keyword.fetch!(opts, :max_fragment_size)
    activation_may_be_delayed? = Keyword.fetch!(opts, :activation_may_be_delayed?)

    # {:ok, _} = AsyncConnection.start_link(Keyword.fetch!(opts, :device_id))
    {:ok, _} = Connection.open(Keyword.fetch!(opts, :device_id), mode: :async)

    {:ok,
     %FirmwareUpdate{
       handler: handler,
       device_id: device_id,
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       firmware_target: firmware_target,
       hardware_version: hardware_version,
       max_fragment_size: max_fragment_size,
       activation_may_be_delayed?: activation_may_be_delayed?
     }}
  end

  @spec start_firmware_update(t(), FirmwareUpdates.image_path()) :: :ok
  def start_firmware_update(runner, image_path) do
    GenServer.call(runner, {:start_firmware_update, image_path})
  end

  @spec stop(t()) :: :ok
  def stop(runner \\ __MODULE__) do
    GenServer.stop(runner, :normal)
  end

  @spec firmware_image_fragment_count() :: non_neg_integer()
  def firmware_image_fragment_count(runner \\ __MODULE__) do
    GenServer.call(runner, :firmware_image_fragment_count)
  end

  @impl true
  def handle_call({:start_firmware_update, image_path}, _from, firmware_update) do
    {command, new_firmware_update} =
      firmware_update
      |> FirmwareUpdate.put_image(image_path)
      |> FirmwareUpdate.next_command(:updating)

    {:ok, command_ref} =
      AsyncConnection.send_command(firmware_update.device_id, command, timeout: 120_000)

    {:reply, :ok, FirmwareUpdate.update_command_ref(new_firmware_update, command_ref)}
  end

  def handle_call(
        :firmware_image_fragment_count,
        _from,
        %FirmwareUpdate{image: image} = firmware_update
      ) do
    count = Image.fragment_count(image)
    {:reply, count, firmware_update}
  end

  @impl true
  # Async responses to commands sent
  def handle_info({:grizzly, :report, report}, firmware_update) do
    case report.type do
      :ack_response ->
        {:noreply, firmware_update}

      :command ->
        handle_report(report, firmware_update)
    end
  end

  @impl true
  def terminate(:normal, firmware_update) do
    :ok = AsyncConnection.stop(firmware_update.device_id)

    :ok
  end

  def terminate(_reason, _firmware_update) do
    :ok
  end

  defp handle_report(%Report{type: :ack_response}, firmware_update) do
    {:noreply, firmware_update}
  end

  defp handle_report(report, firmware_update) do
    Logger.debug("[Grizzly] Handling FW update command #{inspect(report)}")

    case report do
      %Report{status: :complete, type: :command, command: nil} ->
        Logger.warn(
          "[Grizzly] FW update report of type :command has no command: #{inspect(report)}. Ignoring it."
        )

        {:noreply, firmware_update}

      _other ->
        command = report.command
        new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)

        respond_to_handler(format_handler_spec(firmware_update.handler), command)

        if new_firmware_update.state == :complete do
          {:stop, :normal, firmware_update}
        else
          maybe_desired_state_with_delay = FirmwareUpdate.continuation(new_firmware_update)

          final_firmware_update =
            handle_continuation(maybe_desired_state_with_delay, new_firmware_update)

          {:noreply, final_firmware_update}
        end
    end
  end

  defp handle_continuation(nil, firmware_update) do
    firmware_update
  end

  defp handle_continuation({desired_state, delay_msecs}, firmware_update) do
    Logger.debug(
      "[Grizzly] Handling FW update continuation to desired state #{inspect(desired_state)} after #{
        delay_msecs
      } msecs"
    )

    {command, new_firmware_update} = FirmwareUpdate.next_command(firmware_update, desired_state)
    :timer.sleep(delay_msecs)

    {:ok, command_ref} =
      AsyncConnection.send_command(new_firmware_update.device_id, command, timeout: 120_000)

    Logger.debug("[Grizzly] Sent FW update continuation #{inspect(command)}")

    continued_firmware_update =
      FirmwareUpdate.update_command_ref(new_firmware_update, command_ref)

    maybe_desired_state_with_delay = FirmwareUpdate.continuation(continued_firmware_update)
    handle_continuation(maybe_desired_state_with_delay, continued_firmware_update)
  end

  defp format_handler_spec({_handler_module, _handler_opts} = handler), do: handler
  defp format_handler_spec(handler) when is_pid(handler), do: handler
  defp format_handler_spec(handler), do: {handler, []}

  defp respond_to_handler(handler, command) when is_pid(handler) do
    send(handler, {:grizzly, :report, command})
  end

  defp respond_to_handler({handler_module, handler_opts}, command) do
    # TODO - Consider using a handler runner genserver for calling the plugin inclusion handler
    spawn_link(fn -> handler_module.handle_command(command, handler_opts) end)
  end
end
