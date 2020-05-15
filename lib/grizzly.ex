defmodule Grizzly do
  @moduledoc """
  Send commands to Z-Wave devices

  Grizzly provides the `send_command` function as the way to to send a command
  to Z-Wave devices.

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

  Also, a command can have options. Namely, `:timeout` (default `5_000`) and
  `:retries` (default `2`).

  ```elixir
  Grizzly.send_command(node_id, :switch_binary_get, [], timeout: 10_000, retries: 5)
  ```

  The `send_command` returns one 4 values:

  1. `:ok` - the command was sent and everything is okay
  1. `{:ok, Command.t()}` - the command was sent and the Z-Wave device
     responded with another command (probably some type of report)
  1. `{:error, :including}` - current the Z-Wave controller is adding or
     removing a device and commands cannot be processed right now
  1. `{:error, reason}` - there was some other reason for an error
  1. `{:queued, reference, seconds}` - the node is a sleeping node so the
      controller queued the command and expects the command to be sent in after
      the reported seconds have passed.

  """

  alias Grizzly.{Connection, Inclusions, Node}
  alias Grizzly.Commands.Table
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave.Command

  @type send_command_response ::
          :ok
          | {:ok, Command.t()}
          | {:error, :including | any()}
          | {:queued, reference(), non_neg_integer()}

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()

  @type command_opt ::
          {:timeout, non_neg_integer()}
          | {:retries, non_neg_integer()}
          | {:handler, module() | {module(), args :: list()}}

  @type command :: atom()

  @doc """
  Send a command to the node via the node id
  """
  @spec send_command(Node.id(), command(), args :: list(), [command_opt()]) ::
          send_command_response()
  def send_command(node_id, command_name, args \\ [], opts \\ []) do
    # always open a connection. If the connection is already opened this
    # will not establish a new connection

    with false <- Inclusions.inclusion_running?(),
         {command_module, default_opts} <- Table.lookup(command_name),
         {:ok, command} <- command_module.new(args),
         {:ok, _} <- Connection.open(node_id) do
      Connection.send_command(node_id, command, Keyword.merge(default_opts, opts))
    else
      true ->
        {:error, :including}

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
end
