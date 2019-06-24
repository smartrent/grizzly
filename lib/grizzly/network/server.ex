defmodule Grizzly.Network.Server do
  use GenServer

  require Logger
  alias Grizzly.{Node, Notifications, SeqNumber, CommandClass}
  alias Grizzly.Network.Commands, as: NetworkCommands
  alias Grizzly.Network.State, as: NetworkState
  alias Grizzly.CommandClass.CommandClassVersion

  defmodule State do
    @type t :: %__MODULE__{
            nodes: [Node.t()]
          }

    defstruct nodes: []
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  List all the nodes on network
  """
  @spec all() :: [Node.t()]
  def all() do
    GenServer.call(__MODULE__, :all)
  end

  @doc """
  Reset the network and network state

  The `timeout` argument defaults to 60 seconds.
  """
  @spec reset(timeout :: non_neg_integer) :: :ok | {:error, :network_busy}
  def reset(timeout \\ 60_000) do
    GenServer.call(__MODULE__, :reset, timeout)
  end

  @doc """
  Get a Node from the network to use by the Node's id
  """
  @spec get_node(Node.node_id()) :: {:ok, Node.t()} | {:error, :node_not_found}
  def get_node(node_id) do
    GenServer.call(__MODULE__, {:get_node, node_id})
  end

  @doc """
    Update the command class version of a node
  """
  @spec update_command_class_versions(Node.t(), :sync | :async) :: :ok
  def update_command_class_versions(zw_node, mode) do
    GenServer.call(__MODULE__, {:update_command_class_versions, zw_node, mode}, 30_000)
  end

  @doc """
    Get the version of a node's command class if not already known
  """
  @spec command_class_version(Node.t(), CommandClass.t()) ::
          {:ok, non_neg_integer} | {:error, atom}
  def command_class_version(zw_node, command_class) do
    GenServer.call(__MODULE__, {:command_class_version, command_class, zw_node})
  end

  def init(_) do
    :ok = Notifications.subscribe(:controller_connected)
    :ok = Notifications.subscribe(:node_added)
    :ok = Notifications.subscribe(:node_removed)
    {:ok, %State{}}
  end

  def handle_call(:all, _from, %State{nodes: nodes} = state) do
    {:reply, nodes, state}
  end

  def handle_call(:reset, _from, %State{} = state) do
    with {:ok, :done} <- NetworkCommands.reset_controller(),
         {:ok, zw_nodes} <- get_nodes(state) do
      {:reply, :ok, %{state | nodes: zw_nodes}}
    else
      {:error, _} = error -> error
    end
  end

  def handle_call({:get_node, node_id}, _from, %State{nodes: nodes} = state) do
    case Enum.find(nodes, &(&1.id == node_id)) do
      nil ->
        {:reply, {:error, :node_not_found}, state}

      zw_node ->
        {:reply, {:ok, zw_node}, state}
    end
  end

  def handle_call({:update_command_class_versions, zw_node, :async}, _from, state) do
    _ = Logger.info("Updating command class version of node #{zw_node.id}")
    # spawn unlinked to be unaffected by command timeouts
    spawn(fn ->
      update_cc_versions(zw_node)
    end)

    {:reply, :ok, state}
  end

  def handle_call({:update_command_class_versions, zw_node, :sync}, _from, state) do
    update_cc_versions(zw_node)
    {:reply, :ok, state}
  end

  def handle_call(
        {
          :command_class_version,
          %{name: name} = command_class,
          zw_node
        },
        _from,
        %State{nodes: nodes} = state
      ) do
    if CommandClass.versioned?(command_class) do
      {:reply, {:ok, command_class.version}, state}
    else
      case get_command_class_version(zw_node, name) do
        {:ok, %{version: version}} ->
          versioned_command_class = CommandClass.set_version(command_class, version)
          updated_zw_node = Node.update_command_class(zw_node, versioned_command_class)
          {:reply, {:ok, version}, %{state | nodes: update_node_list(updated_zw_node, nodes)}}

        {:error, reason} ->
          _ =
            Logger.warn(
              "Failed to get version of command_class #{name} of node #{zw_node.id}: #{reason}"
            )

          {:reply, {:error, reason}, state}
      end
    end
  end

  def handle_cast({:node_updated, zw_node}, %State{nodes: nodes} = state) do
    _ = Logger.debug("Updating list of nodes with updated node #{inspect(zw_node)}")
    {:noreply, %{state | nodes: update_node_list(zw_node, nodes)}}
  end

  def handle_info(:controller_connected, %State{} = state) do
    case get_nodes(state) do
      {:ok, nodes} ->
        Notifications.broadcast(:network_ready)
        NetworkState.set(:idle)
        {:noreply, %{state | nodes: nodes}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  def handle_info({:node_removed, node_id}, %State{nodes: nodes} = state) do
    case Enum.find(nodes, &(&1.id == node_id)) do
      nil ->
        _ = Logger.warn("Unknown node #{node_id} was removed")
        {:noreply, state}

      zw_node ->
        :ok = Node.disconnect(zw_node)
        new_nodes = Enum.filter(nodes, &(&1.id != node_id))
        {:noreply, %{state | nodes: new_nodes}}
    end
  end

  def handle_info({:node_added, zw_node}, %State{nodes: nodes} = state) do
    {:noreply, %{state | nodes: nodes ++ [zw_node]}}
  end

  defp get_nodes(%State{}) do
    case NetworkCommands.get_nodes_on_network() do
      {:ok, nodes} ->
        {:ok, Enum.map(nodes, &set_up_node/1)}

      {:error, reason} = error ->
        _ = Logger.warn("Unable to load nodes from Z-Wave network: #{inspect(reason)}")
        error
    end
  end

  defp set_up_node(%Node{id: 1} = zw_node) do
    case NetworkCommands.get_node_info(1) do
      {:ok, node_info} ->
        struct(zw_node, node_info)

      {:error, reason} ->
        _ = Logger.warn("Unable to get node info for node id: #{1} due to #{inspect(reason)}")
        zw_node
    end
    |> Node.initialize_command_versions()
  end

  defp set_up_node(%Node{id: node_id} = zw_node) do
    with {:ok, node_info} <- NetworkCommands.get_node_info(node_id),
         updated_zw_node <- Node.update(zw_node, node_info),
         {:ok, connected_zw_node} <- Node.connect(updated_zw_node),
         {:ok, zw_node} <- add_lifeline_group_if_awake(connected_zw_node) do
      zw_node
    else
      {:error, reason} ->
        _ = Logger.warn("Unable to set up node for node id: #{node_id} due to #{inspect(reason)}")
        zw_node
    end
  end

  # TODO - schedule adding a lifeline group when the device awakens?
  defp add_lifeline_group_if_awake(zw_node) do
    if not Node.has_command_class?(zw_node, :wake_up) do
      Node.add_lifeline_group(zw_node)
    else
      {:ok, zw_node}
    end
  end

  defp update_cc_versions(zw_node) do
    _ = Logger.info("Updating command class version of node #{zw_node.id}")
    updated_zw_node = do_update_command_class_versions(zw_node)
    GenServer.cast(__MODULE__, {:node_updated, updated_zw_node})
    Notifications.broadcast(:node_updated, updated_zw_node)
  end

  # Update the command class versions of a node. This can take a while.
  defp do_update_command_class_versions(%Node{id: id, command_classes: command_classes} = zw_node) do
    _ =
      Logger.info(
        "[GRIZZLY] Getting #{Enum.count(command_classes)} command class versions for node #{id}"
      )

    updated_command_classes =
      Enum.map(
        command_classes,
        fn %CommandClass{name: name, version: default_version} = command_class ->
          case get_command_class_version(zw_node, name) do
            {:ok, %{version: version}} ->
              CommandClass.set_version(command_class, version)

            {:error, reason} ->
              _ =
                Logger.warn(
                  "[GRIZZLY] Failed to get version of command class #{inspect(command_class)} in node #{
                    inspect(zw_node)
                  }: #{inspect(reason)}. Keeping default version #{inspect(default_version)}"
                )

              CommandClass.set_version(command_class, default_version)
          end
        end
      )

    _ = Logger.debug("Got command class versions for node #{id}")
    %Node{zw_node | command_classes: updated_command_classes}
  end

  defp get_command_class_version(zw_node, command_class_name) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      zw_node,
      CommandClassVersion.Get,
      seq_number: seq_number,
      command_class: command_class_name
    )
  end

  defp update_node_list(zw_node, nodes) do
    nodes_with_index = Enum.with_index(nodes)

    case Enum.find(nodes_with_index, fn {znode, _index} -> znode.id == zw_node.id end) do
      nil ->
        _ = Logger.info("Adding node #{zw_node.id} to the list of nodes")
        [zw_node | nodes]

      {_, index} ->
        List.replace_at(nodes, index, zw_node)
    end
  end
end
