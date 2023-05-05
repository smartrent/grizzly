defmodule Grizzly do
  @moduledoc """
  Send commands to Z-Wave devices

  Grizzly provides the `send_command` function as the way to send a command to
  Z-Wave devices.

  The `send_command` function takes the node id that you are trying to send a
  command to, the command name, and optionally command arguments and command
  options.

  A basic command that has no options or arguments looks like this:

  ```elixir
  Grizzly.send_command(node_id, :switch_binary_get)
  ```

  A command with command arguments:

  ```elixir
  Grizzly.send_command(node_id, :switch_binary_set, value: :off)
  ```

  Also, a command can have options.

  ```elixir
  Grizzly.send_command(node_id, :switch_binary_get, [], timeout: 10_000, retries: 5)
  ```

  Some possible return values from `send_command` are:

  1. `{:ok, Grizzly.Report.t()}` - the command was sent and the Z-Wave device
     responded with a report. See `Grizzly.Report` for more information.
  1. `{:error, :including}` - current the Z-Wave controller is adding or
     removing a device and commands cannot be processed right now
  1. `{:error, :firmware_updating}` - current the Z-Wave controller is updating firmware and commands cannot be processed right now
  1. `{:error, reason}` - there was some other reason for an error, two
     common ones are: `:nack_response`

  For a more detailed explanation of the responses from a `send_command` call
  see the typedoc for `Grizzly.send_command_response()`.

  # Events from Z-Wave

  Events generating from a Z-Wave device, for example a motion detected event,
  can be handled via the `Grizzly.subscribe_command/1` and
  `Grizzly.subscribe_commands/1` functions. This will allow you to subscribe
  to specific commands. When the command is received from the Z-Wave network
  it will placed in a `Grizzly.Report` and set to the subscribing process. The
  node that generated the report can be accessed with the `:node_id` field in
  the report.

  ```elixir
  iex> Grizzly.subscribe_command(:battery_report)

  # sometime latter

  iex> flush
  {:grizzly, :event, %Grizzly.Report{command: %Grizzly.ZWave.Command{name: :battery_report}}}
  ```

  """

  alias Grizzly.Commands.Table
  alias Grizzly.{Connection, FirmwareUpdates, Inclusions, Report, VersionReports, VirtualDevices}
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.{ZIPGateway, ZWave}
  alias Grizzly.ZWave.Commands.RssiReport

  require Logger

  import Grizzly.VersionReports, only: [is_extra_command: 1]

  @typedoc """
  The response from sending a Z-Wave command

  When everything is okay the response will be `{:ok, Grizzly.Report{}}`. For
  documentation about a report see `Grizzly.Report` module.

  When there are errors the response will be in the pattern of
  `{:error, reason}`.

  Three reasons that Grizzly supports for all commands are `:nack_response`,
  `:update_firmware`, and `:including`.

  In you receive the reason for the error to be `:including` that means the
  controller is in an inclusion state and your command will be dropped if we
  tried to send it. So we won't allow sending a Z-Wave command during an
  inclusion. It's best to wait and try again once your application is done
  trying to include.

  ### Nack response

  A `:nack_response` normally means that the Z-Wave node that you were trying
  to send a command to is unreachable and did not receive your command at all.
  This could mean that the Z-Wave network is overloaded and you should reissue
  the command, the device is too far from the controller, or the device is no
  longer part of the Z-Wave network.

  Grizzly by default will try a command 3 times before sending returning a
  `:nack_response`. This is configurable via the `:retries` command option in
  the `Grizzly.send_command/4` function. This is useful if you are going to
  have a known spike in Z-Wave traffic.

  ### Queue full

  When send commands to a device that sleeps (normally these are sensor type of
  devices) and the sleeping device is not awake these commands get queued up to
  be sent once the device wakes up and tells the Z-Wave network that it is awake.
  However, there is only a limited amount of commands that can be queued at once.
  When sending a command to a device when the queue is full you will receive the
  `{:error, :queue_full}` return from `Grizzly.send_command/4`. The reason this
  is an error is because the device will never receive the command that you
  tried to send.
  """
  @type send_command_response() ::
          {:ok, Report.t()}
          | {:error, :including | :updating_firmware | :nack_response | :queue_full | any()}

  @type seq_number() :: non_neg_integer()

  @type node_id() :: non_neg_integer()

  @typedoc """
  A custom handler for the command.

  See `Grizzly.CommandHandler` behaviour for more documentation.
  """
  @type handler_spec() :: {module(), args :: any()}

  @type handler() :: module() | handler_spec()

  @typedoc """
  Options for `Grizzly.send_command/4`.

  * `:timeout` - Time (in milliseconds) to wait for an ACK or report before timing out.
    Maximum 140 seconds. Default `5_000`.
  * `:retries` - Number of retries in case the node responds with a NACK. Default `0`.
  * `:handler` - A custom response handler (see `Grizzly.CommandHandler`).
  * `:transmission_stats` - If true, transmission stats will be included with the
    returned report (if available). Default `false`.
  * `:supervision?` - Whether to use Supervision CC encapsulation. Default `false`.
  * `:status_updates?` - If true, the calling process will receive messages when
    a supervision status update is received from the destination node. Default `false`.
  """
  @type command_opt() ::
          {:timeout, non_neg_integer()}
          | {:retries, non_neg_integer()}
          | {:handler, module() | handler_spec()}
          | {:transmission_stats, boolean()}
          | {:supervision?, boolean()}
          | {:status_updates?, boolean()}

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
  Send a command to the node via the node id or to Z/IP Gateway

  To talk to your controller directly you can pass `:gateway` as the node id.
  This is helpful because your controller might not always be the same node id
  on any given network. This ensures that not matter node id your controller is
  you will still be able to query it and make it perform Z-Wave functions. There
  are many Z-Wave functions a controller do. There are helper functions for
  these functions in `Grizzly.Network` and `Grizzly.Node`.

  **NOTE:** The `:handler` and `:supervision?` options are not compatible. If
  `:supervision?` is true, any custom handler will be ignored.
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

    with false <- including? or updating_firmware?,
         {command_module, default_opts} <- Table.lookup(command_name),
         {:ok, command} <- command_module.new(args),
         {:ok, _} <- Connection.open(node_id) do
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
  Send a raw binary to the Z-Wave node

  This function does not block and expects the sending process to handle the
  lifecycle of the command being sent. This maximizes control but minimizes
  safety and puts things such as timeouts, retries, and response handling in
  the hand of the calling process.

  When sending the binary ensure the binary is the encoded
  `Grizzly.ZWave.Commands.ZIPPacket`.

  ```elixir
  seq_no = 0x01
  {:ok, my_command} = Grizzly.ZWave.Commands.SwitchBinaryGet.new()
  {:ok, packet} = Grizzly.ZWave.Commands.ZIPPacket.with_zwave_command(my_command, seq_no)
  binary = Grizzly.ZWave.to_binary(packet)

  Grizzly.send_binary(node_id, binary)
  ```

  This is helpful when you need very fine grade control of the Z/IP Packet or if
  you not expecting a response from a Z-Wave network to handle the back and
  forth between your application and the Z-Wave network. Also, this can be useful
  for debugging purposes.

  First check if `send_command/4` will provide the functionality that is needed
  before using this function.

  After sending a binary packet the calling process will receive messages in
  the form of:

  ```elixir
  {:grizzly, :binary_response, binary}
  ```
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
  Subscribe to a command event from a Z-Wave device.
  """
  @spec subscribe_command(command()) :: :ok
  defdelegate subscribe_command(command_name), to: Messages, as: :subscribe

  @doc """
  Unsubscribe from an event.
  """
  @spec unsubscribe_command(command()) :: :ok
  defdelegate unsubscribe_command(command_name), to: Messages, as: :unsubscribe

  @doc """
  Subscribe to many events from a Z-Wave device.
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
  List the support commands
  """
  @spec list_commands() :: [atom()]
  def list_commands() do
    Enum.map(Table.dump(), fn {command, _} -> command end)
  end

  @doc """
  List the command for a particular command class
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

  @doc "Restarts the Z/IP Gateway process if it is running."
  @spec restart_zipgateway :: :ok
  defdelegate restart_zipgateway(), to: Grizzly.ZIPGateway.Supervisor

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
