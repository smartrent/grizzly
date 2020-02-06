defmodule Grizzly do
  alias Grizzly.{Connection, Inclusions, Node}
  alias Grizzly.Commands.Table
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave.Command

  @type send_command_response :: :ok | {:ok, Command.t()} | {:error, :including | any()}

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

  @spec subscribe_command(command()) :: :ok
  def subscribe_command(command_name) do
    Messages.subscribe(command_name)
  end

  @spec subscribe_commands([command()]) :: :ok
  def subscribe_commands(command_names) do
    Enum.each(command_names, &subscribe_command/1)
  end

  @spec unsubscribe_command(command()) :: :ok
  def unsubscribe_command(command_name) do
    Messages.unsubscribe(command_name)
  end
end
