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

  alias Grizzly.{Connection, Inclusions, FirmwareUpdates, Report}
  alias Grizzly.Commands.Table
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave

  @typedoc """
  The response from sending a Z-Wave command

  When everything is okay the response will be `{:ok, Grizzly.Report{}}`. For
  documentation about a report see `Grizzly.Report` module.

  When there are errors the response will be in the pattern of
  `{:error, reason}`.

  Three reasons that Grizzly supports for all commands are `:nack_response`,
  `:update_firmware`, and `:including`.

  A `:nack_response` normally means that the Z-Wave node that you were trying
  to send a command to is unreachable and did not receive your command at all.
  This could mean that the Z-Wave network is overloaded and you should reissue
  the command, the device is too far from the controller, or the device is no
  longer part of the Z-Wave network.

  Grizzly by default will try a command 3 times before sending returning a
  `:nack_response`. This is configurable via the `:retries` command option in
  the `Grizzly.send_command/4` function. This is useful if you are going to
  have a known spike in Z-Wave traffic.

  In you receive the reason for the error to be `:including` that means the
  controller is in an inclusion state and your command will be dropped if we
  tried to send it. So we won't allow sending a Z-Wave command during an
  inclusion. It's best to wait and try again once your application is done
  trying to include.
  """
  @type send_command_response() ::
          {:ok, Report.t()}
          | {:error, :including | :updating_firmware | :nack_response | any()}

  @type seq_number() :: non_neg_integer()

  @type node_id() :: non_neg_integer()

  @typedoc """
  A custom handler for the command.

  See `Grizzly.CommandHandler` behaviour for more documentation.
  """
  @type handler() :: module() | {module(), args :: any()}

  @type command_opt() ::
          {:timeout, non_neg_integer()}
          | {:retries, non_neg_integer()}
          | {:handler, handler()}
          | {:transmission_stats, boolean()}

  @type command :: atom()

  @doc """
  Send a command to the node via the node id
  """
  @spec send_command(ZWave.node_id(), command(), args :: list(), [command_opt()]) ::
          send_command_response()
  def send_command(node_id, command_name, args \\ [], opts \\ []) do
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
  Subscribe to a command event from a Z-Wave device
  """
  @spec subscribe_command(command()) :: :ok
  def subscribe_command(command_name) do
    Messages.subscribe(command_name)
  end

  @doc """
  Subscribe to many events from a Z-Wave device
  """
  @spec subscribe_commands([command()]) :: :ok
  def subscribe_commands(command_names) do
    Enum.each(command_names, &subscribe_command/1)
  end

  @doc """
  Unsubscribe to an event
  """
  @spec unsubscribe_command(command()) :: :ok
  def unsubscribe_command(command_name) do
    Messages.unsubscribe(command_name)
  end

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
      command.command_class.name() == command_class_name
    end)
    |> Enum.map(fn {command, _} -> command end)
  end
end
