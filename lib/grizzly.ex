defmodule Grizzly do
  use TelemetryRegistry

  telemetry_event %{
    event: [:grizzly, :zip_gateway, :crash],
    description: "Emitted when the Z/IP Gateway process exits abnormally.",
    measurements: "N/A",
    metadata: "N/A"
  }

  telemetry_event %{
    event: [:grizzly, :zwave, :s2_resynchronization],
    description: "Emitted when an S2 resynchronization event occurs.",
    measurements: "%{system_time: non_neg_integer()}",
    metadata: "%{node_id: non_neg_integer(), reason: non_neg_integer()}"
  }

  @moduledoc """
  Send commands, subscribe to unsolicited events, and other helpers.

  ## Unsolicited Events

  In order to receive unsolicited events from the Z-Wave network you must subscribe to the
  corresponding command (e.g. `:battery_report`, `:alarm_report`, etc.).

  Whenever an unsolicited event is received from a device, subscribers will receive messages
  in the following format:

      {:grizzly, :event, %Grizzly.Report{}}

  The `Grizzly.Report` struct will contain the id of the sending node, a `Grizzly.ZWave.Command`
  struct with the command name and arguments, and any additional metadata. Refer to `Grizzly.Report`
  and `Grizzly.ZWave.Command` for details.

  ## Telemetry

  #{telemetry_docs()}
  """

  alias Grizzly.Commands.Table
  alias Grizzly.{Connection, FirmwareUpdates, Inclusions, Report, VersionReports, VirtualDevices}
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.{ZIPGateway, ZWave}
  alias Grizzly.ZWave.Commands.RssiReport

  require Logger

  import Grizzly.VersionReports, only: [is_extra_command: 1]

  @typedoc """
  The response from sending a Z-Wave command.

  When everything is okay the response will be `{:ok, Grizzly.Report{}}`. For
  documentation about a report see `Grizzly.Report` module.

  When there are errors the response will be in the pattern of
  `{:error, reason}`.

  Three reasons that Grizzly supports for all commands are `:nack_response`,
  `:update_firmware`, and `:including`.

  ### Including

  An `:including` response means that the controller is in inclusion, exclusion,
  or learn mode and cannot process any commands. Either cancel the inclusion (see
  `Grizzly.Inclusions`) or wait until the inclusion is complete before trying again.

  ### Nack response

  A `:nack_response` normally means that the Z-Wave node that you were trying
  to send a command to is unreachable and did not receive your command at all.
  This could mean that the Z-Wave network is overloaded and you should reissue
  the command, the device is too far from the controller, or the device is no
  longer part of the Z-Wave network (e.g. due to a factory reset).

  By default, Grizzly will retry the command twice before sending returning a
  `:nack_response`. This is configurable via the `:retries` command option in
  the `Grizzly.send_command/4` function. This helps increase the reliability of
  sending commands during Z-Wave network congestion.

  ### Queue full

  Sleeping devices can only receive commands when they are wake up, so Z/IP Gateway
  queues commands to be sent when it receives a wake up notification from the device.
  However, it will only queue a limited number of commands. A `:queue_full` response
  is returned in this situation.
  """
  @type send_command_response() ::
          {:ok, Report.t()}
          | {:error, :including | :updating_firmware | :nack_response | :queue_full | any()}

  @type seq_number() :: non_neg_integer()

  @type node_id() :: non_neg_integer()

  @typedoc """
  A custom handler for the command.

  See the `Grizzly.CommandHandler` behaviour for more documentation.
  """
  @type handler_spec() :: {module(), args :: any()}

  @type handler() :: module() | handler_spec()

  @typedoc """
  Options for `Grizzly.send_command/4`.

  * `:timeout` - Time (in milliseconds) to wait for an ACK or report before timing out.
    Maximum 140 seconds. Default `15_000`.
  * `:retries` - Number of retries in case the node responds with a NACK. Default `0`.
  * `:handler` - A custom response handler (see `Grizzly.CommandHandler`). Ignored if
    `supervision?` is true.
  * `:transmission_stats` - If true, transmission stats will be included with the
    returned report (if available). Default `false`.
  * `:supervision?` - Whether to use Supervision CC encapsulation. Default `false`.
  * `:status_updates?` - If true, the calling process will receive messages when
    a supervision status update is received from the destination node. Default `false`.
  * `:mode` - The connection mode to use when sending the command. Defaults to `:sync`.
    Using `:async` will result in the returned `Grizzly.Report` always having a type of
    `:queued_delay`.
  """
  @type command_opt() ::
          {:timeout, non_neg_integer()}
          | {:retries, non_neg_integer()}
          | {:handler, module() | handler_spec()}
          | {:transmission_stats, boolean()}
          | {:supervision?, boolean()}
          | {:status_updates?, boolean()}
          | {:mode, Connection.mode()}

  @type command :: atom()

  @doc """
  Guard for checking if device is a virtual device or not
  """
  defguard is_virtual_device(device_id) when is_tuple(device_id)

  @doc """
  Check to if the device id is a virtual device or a regular Z-Wave devices
  """
  @spec virtual_device?(:gateway | ZWave.node_id() | VirtualDevices.id()) :: boolean()
  def virtual_device?(device_id) do
    is_virtual_device(device_id)
  end

  @doc """
  Send a command to the node via the node id or to Z/IP Gateway.

  ## Arguments

  * `node_id` - The node id to send the command to. If `:gateway` is passed, the command
    will be sent to the locally running Z/IP Gateway -- this is useful if this controller
    has a node id other than 1.

  * `command` - The command to send. See `Grizzly.Commands.Table` for a list of available commands
    and their associated modules.

  * `args` - A list of arguments to pass to the command. See the associated command module
    for details.

  * `opts` - A keyword list of options to control how the command is sent and processed.
    See `t:Grizzly.command_opt/0` for details.

  ## Usage

      # A command with no arguments or options:
      Grizzly.send_command(node_id, :switch_binary_get)

      # ... with arguments:
      Grizzly.send_command(node_id, :switch_binary_set, value: :off)

      # ... with arguments and options:
      Grizzly.send_command(node_id, :switch_binary_get, [], timeout: 10_000, retries: 5)


  ## Return values and errors

  Following are the most common return values and errors that you will see. For a
  complete list, see `t:Grizzly.send_command_response/0`.

  * `{:ok, Grizzly.Report.t()}` - the command was sent and the Z-Wave device
      responded with an ACK or a report. See `Grizzly.Report` for more information.
  * `{:error, :including}` - the Z-Wave controller is currently in inclusion or exclusion mode
  * `{:error, :firmware_updating}` - the Z-Wave controller is undergoing a firmware update
  * `{:error, reason}` - see `t:Grizzly.send_command_response/0`
  """
  @spec send_command(
          ZWave.node_id() | :gateway | VirtualDevices.id(),
          command(),
          args :: list(),
          [command_opt()]
        ) ::
          send_command_response()
  def send_command(node_id, command_name, args \\ [], opts \\ [])

  def send_command(node_id, command_name, args, _opts) when is_virtual_device(node_id) do
    with {command_module, _default_opts} <- Table.lookup(command_name),
         {:ok, command} <- command_module.new(args) do
      VirtualDevices.send_command(node_id, command)
    end
  end

  def send_command(
        :gateway,
        :version_command_class_get,
        [command_class: command_class],
        _opts
      )
      when is_extra_command(command_class) do
    {:ok, version_report} = VersionReports.version_report_for(command_class)
    {:ok, %Report{command: version_report, node_id: :gateway, status: :complete, type: :command}}
  end

  def send_command(node_id, command_name, args, opts) do
    :ok = maybe_log_warning(command_name)

    send_command_no_warn(node_id, command_name, args, opts)
  end

  # This is only to be used by Grizzly as it migrates into the higher
  # level helper modules, for example Grizzly.SwitchBinary.
  @doc false
  def send_command_no_warn(node_id, command_name, args, opts) do
    # always open a connection. If the connection is already opened this
    # will not establish a new connection
    including? = Inclusions.inclusion_running?()
    updating_firmware? = FirmwareUpdates.firmware_update_running?()

    open_opts = Keyword.take(opts, [:mode])

    with false <- including? or updating_firmware?,
         {command_module, default_opts} <- Table.lookup(command_name),
         {:ok, command} <- command_module.new(args),
         {:ok, _} <- Connection.open(node_id, open_opts) do
      Connection.send_command(node_id, command, Keyword.merge(default_opts, opts))
    else
      true ->
        reason = if including?, do: :including, else: :updating_firmware
        {:error, reason}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Send a raw binary to the Z-Wave node.

  This function does not block and expects the sending process to handle the
  lifecycle of the command being sent. This maximizes control but minimizes
  safety and puts things such as timeouts, retries, and response handling in
  the hand of the calling process.

  When sending a binary command to a Z-Wave node, the binary must be encapsulated
  in a Z/IP Packet (see `Grizzly.ZWave.Commands.ZIPPacket`).

      seq_no = 0x01
      {:ok, my_command} = Grizzly.ZWave.Commands.SwitchBinaryGet.new()
      {:ok, packet} = Grizzly.ZWave.Commands.ZIPPacket.with_zwave_command(my_command, seq_no)
      binary = Grizzly.ZWave.to_binary(packet)

      Grizzly.send_binary(node_id, binary)

  This can be useful when you need very fine-grained control of the outgoing Z/IP Packet,
  if you need to send a command that has not been implemented in Grizzly yet (contributions
  are welcome!), or for debugging purposes.

  After sending a binary packet the calling process will receive a message in the form of:

      {:grizzly, :binary_response, <<...>>}
  """
  @spec send_binary(ZWave.node_id(), binary()) :: :ok | {:error, :including | :firmware_updating}
  def send_binary(node_id, binary) do
    including? = Inclusions.inclusion_running?()
    updating_firmware? = FirmwareUpdates.firmware_update_running?()

    case {including?, updating_firmware?} do
      {true, _} ->
        {:error, :including}

      {_, true} ->
        {:error, :firmware_updating}

      _can_send ->
        {:ok, _} = Connection.open(node_id, mode: :binary)
        Connection.send_binary(node_id, binary)
    end
  end

  @doc """
  Subscribe to unsolicited events for the given command.
  """
  @spec subscribe_command(command()) :: :ok
  defdelegate subscribe_command(command_name), to: Messages, as: :subscribe

  @doc """
  Unsubscribe from an unsolicited event.
  """
  @spec unsubscribe_command(command()) :: :ok
  defdelegate unsubscribe_command(command_name), to: Messages, as: :unsubscribe

  @doc """
  Subscribe to unsolicited events for multiple commands.
  """
  @spec subscribe_commands([command()]) :: :ok
  def subscribe_commands(command_names) do
    Enum.each(command_names, &subscribe_command/1)
  end

  @doc """
  Subscribe to all events from a particular Z-Wave device.

  NOTE: Subscribers using both `subscribe_node` and `subscribe_command` **will**
  receive duplicate messages.
  """
  defdelegate subscribe_node(node_id), to: Messages

  @doc """
  Subscribe to all events from a group of Z-Wave devices.

  NOTE: Subscribers using both `subscribe_node` and `subscribe_command` **will**
  receive duplicate messages.
  """
  @spec subscribe_nodes([node_id() | VirtualDevices.id()]) :: :ok
  def subscribe_nodes(node_ids) do
    Enum.each(node_ids, &subscribe_node/1)
  end

  @doc """
  Delete a subscription created with `subscribe_node/1`.
  """
  defdelegate unsubscribe_node(node_id), to: Messages

  @doc """
  List all supported Z-Wave commands.
  """
  @spec list_commands() :: [atom()]
  def list_commands() do
    Enum.map(Table.dump(), fn {command, _} -> command end)
  end

  @doc """
  List the supported Z-Wave commands for a particular command class.
  """
  @spec commands_for_command_class(atom()) :: [atom()]
  def commands_for_command_class(command_class_name) do
    Table.dump()
    |> Enum.filter(fn {_command, {command_module, _}} ->
      {:ok, command} = command_module.new([])
      command.command_class == command_class_name
    end)
    |> Enum.map(fn {command, _} -> command end)
  end

  @doc """
  Sends a no-op command to the given node to check its reachability. Transmission
  stats are enabled by default.
  """
  @spec ping(ZWave.node_id(), [command_opt()]) :: send_command_response()
  def ping(node_id, opts \\ []) do
    opts = Keyword.put_new(opts, :transmission_stats, true)
    send_command(node_id, :no_operation, [], opts)
  end

  @doc """
  Reports the gateway's current background RSSI (noise).
  """
  @spec background_rssi() :: {:ok, [RssiReport.param()]} | {:error, any()}
  def background_rssi() do
    case send_command(:gateway, :rssi_get) do
      {:ok, %Report{command: %ZWave.Command{params: params}}} ->
        {:ok, params}

      {_, %Grizzly.Report{type: :timeout}} ->
        {:error, :timeout}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Whether Grizzly supports sending the given command with supervision.
  """
  @spec can_supervise_command?(Grizzly.command()) :: boolean()
  defdelegate can_supervise_command?(command_name),
    to: Grizzly.Commands.Table,
    as: :supports_supervision?

  @doc """
  Restarts the Z/IP Gateway process. An error will be raised if `Grizzly.ZIPGateway.Supervisor`
  is not running.
  """
  @spec restart_zipgateway :: :ok
  defdelegate restart_zipgateway(), to: Grizzly.ZIPGateway.Supervisor

  @doc "Stops the Z/IP Gateway process if it is running."
  @spec stop_zipgateway :: :ok
  defdelegate stop_zipgateway(), to: Grizzly.ZIPGateway.Supervisor

  @doc "Get the current inclusion status."
  @spec inclusion_status() :: Inclusions.status()
  defdelegate inclusion_status(), to: Inclusions.StatusServer, as: :get

  @doc """
  Returns the network's home id. Returns nil if Grizzly is started with `run_zipgateway: false`
  or if Z/IP Gateway has not yet logged the home id.
  """
  @spec home_id() :: binary() | nil
  def home_id() do
    case GenServer.whereis(ZIPGateway.LogMonitor) do
      nil -> nil
      pid -> ZIPGateway.LogMonitor.home_id(pid)
    end
  end

  @doc """
  Returns the network encryption keys. Returns nil if Grizzly is started with
  `run_zipgateway: false` or if Z/IP Gateway has not yet logged the network keys.
  """
  @spec network_keys() :: [{ZIPGateway.LogMonitor.network_key_type(), binary()}] | nil
  def network_keys() do
    case GenServer.whereis(ZIPGateway.LogMonitor) do
      nil -> nil
      pid -> ZIPGateway.LogMonitor.network_keys(pid)
    end
  end

  @doc """
  Returns the network encryption keys formatted for use with the Zniffer application.
  See `Grizzly.ZIPGateway.LogMonitor.zniffer_network_keys/1` for more information.
  """
  @spec zniffer_network_keys() :: binary() | nil
  def zniffer_network_keys() do
    case GenServer.whereis(ZIPGateway.LogMonitor) do
      nil -> nil
      pid -> ZIPGateway.LogMonitor.zniffer_network_keys(pid)
    end
  end

  @doc """
  Return the options `Grizzly.Supervisor` was started with. Returns nil if supervisor
  is not started.
  """
  @spec options() :: Grizzly.Options.t() | nil
  def options() do
    Agent.get(Grizzly.Options.Agent, &Function.identity/1)
  catch
    :exit, {:noproc, _} ->
      nil
  end

  defp maybe_log_warning(command_name) do
    deprecated_list = [
      :switch_binary_get,
      :switch_binary_set
    ]

    if command_name in deprecated_list do
      new_module = get_new_module(command_name)

      Logger.debug("""
      Calling Grizzly.send_command/4 for command #{inspect(command_name)} is deprecated.

      Please upgrade to using #{inspect(new_module)} to send this command.
      """)
    end

    :ok
  end

  defp get_new_module(:switch_binary_get), do: Grizzly.SwitchBinary
  defp get_new_module(:switch_binary_set), do: Grizzly.SwitchBinary
end
