defmodule Grizzly do
  alias Grizzly.{Connection, Inclusions, Node}
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    SwitchBinaryGet,
    SwitchBinarySet,
    NodeListGet,
    NodeAdd,
    NodeInfoCachedGet
  }

  @type send_command_response :: :ok | {:ok, Command.t()} | {:error, :including | any()}

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()

  @type command ::
          :switch_binary_set
          | :switch_binary_get
          | :node_list_get
          | :node_add
          | :switch_binary_report
          | :node_add_status
          | :node_remove_status
          | :node_info_cached_get

  @doc """
  Send a command to the node via the node id
  """
  @spec send_command(Node.id(), command(), keyword(), keyword()) :: send_command_response()
  def send_command(node_id, command_name, args \\ [], opts \\ []) do
    # always open a connection. If the connection is already opened this
    # will not establish a new connection

    with false <- Inclusions.inclusion_running?(),
         command_module <- lookup(command_name),
         {:ok, command} <- command_module.new(args),
         {:ok, _} <- Connection.open(node_id) do
      Connection.send_command(node_id, command, opts)
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

  defp lookup(:switch_binary_get), do: SwitchBinaryGet
  defp lookup(:switch_binary_set), do: SwitchBinarySet
  defp lookup(:node_list_get), do: NodeListGet
  defp lookup(:node_add), do: NodeAdd
  defp lookup(:node_info_cached_get), do: NodeInfoCachedGet

  defp lookup(_) do
    raise ArgumentError, """
    The command you are trying to send is not supported
    """
  end
end
