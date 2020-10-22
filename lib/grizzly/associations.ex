defmodule Grizzly.Associations do
  @moduledoc false

  use GenServer
  alias Grizzly.{Options, ZWave}

  @type grouping_id() :: byte()

  defmodule State do
    @moduledoc false

    defstruct file_path: nil
  end

  defmodule Association do
    @moduledoc false

    alias Grizzly.ZWave

    @type t() :: %__MODULE__{
            grouping_id: byte(),
            node_ids: [ZWave.node_id()]
          }

    defstruct grouping_id: nil, node_ids: []
  end

  @doc """
  Start the Associations server

  If you pass the GenServer option for a name you can access the server with
  that name. However, if no name is passed to the `server_opts` then it will
  fallback to using the `Grizzly.Associations` module name
  """
  @spec start_link(Options.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(grizzly_options, server_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      grizzly_options,
      Keyword.put_new(server_opts, :name, __MODULE__)
    )
  end

  @doc """
  Save the node ids to the grouping id
  """
  @spec save(GenServer.name(), grouping_id(), [ZWave.node_id()]) :: :ok
  def save(server \\ __MODULE__, grouping_id, node_ids) do
    GenServer.call(server, {:save, grouping_id, node_ids})
  end

  @doc """
  Get all the associations
  """
  @spec get_all(GenServer.name()) :: [Association.t()]
  def get_all(server \\ __MODULE__) do
    GenServer.call(server, :get_all)
  end

  @doc """
  Get an association by the grouping id
  """
  @spec get(GenServer.name(), grouping_id()) :: Association.t() | nil
  def get(server \\ __MODULE__, grouping_id) do
    GenServer.call(server, {:get, grouping_id})
  end

  @doc """
  Delete all the associations
  """
  @spec delete_all(GenServer.name()) :: :ok
  def delete_all(server \\ __MODULE__) do
    GenServer.call(server, :delete_all)
  end

  @doc """
  Delete all the nodes from the grouping
  """
  @spec delete_all_nodes_from_grouping(GenServer.name(), grouping_id()) :: :ok
  def delete_all_nodes_from_grouping(server \\ __MODULE__, grouping_id) do
    GenServer.call(server, {:delete_all_from_grouping, grouping_id})
  end

  @doc """
  Delete the specified nodes from the association grouping
  """
  @spec delete_nodes_from_grouping(GenServer.name(), grouping_id(), [ZWave.node_id()]) ::
          :ok | {:error, :invalid_grouping_id}
  def delete_nodes_from_grouping(server \\ __MODULE__, grouping_id, nodes) do
    GenServer.call(server, {:remove_nodes_from_grouping, grouping_id, nodes})
  end

  @doc """
  Delete the nodes from each association group
  """
  @spec delete_nodes_from_all_groupings(GenServer.name(), [ZWave.node_id()]) :: :ok
  def delete_nodes_from_all_groupings(server \\ __MODULE__, nodes) do
    GenServer.call(server, {:delete_nodes_from_all_associations, nodes})
  end

  @impl GenServer
  def init(%Options{associations_file: nil}) do
    :ignore
  end

  def init(%Options{associations_file: file}) do
    if File.exists?(file) do
      {:ok, %State{file_path: file}}
    else
      try_create_file(file)
    end
  end

  @impl GenServer
  def handle_call({:save, grouping_id, node_ids}, _from, state) do
    %State{file_path: file_path} = state

    new_associations =
      file_path
      |> read_all_associations()
      |> Map.put(grouping_id, node_ids)

    write_associations(file_path, new_associations)

    {:reply, :ok, state}
  end

  def handle_call(:get_all, _from, state) do
    %State{file_path: file_path} = state

    associations =
      file_path
      |> read_all_associations()
      |> Enum.reduce([], fn {groupind_id, node_ids}, assocs ->
        assoc = %Association{grouping_id: groupind_id, node_ids: node_ids}

        assocs ++ [assoc]
      end)

    {:reply, associations, state}
  end

  def handle_call({:get, grouping_id}, _from, state) do
    %State{file_path: file_path} = state

    case Map.get(read_all_associations(file_path), grouping_id) do
      nil ->
        {:reply, nil, state}

      node_ids ->
        association = %Association{grouping_id: grouping_id, node_ids: node_ids}

        {:reply, association, state}
    end
  end

  def handle_call(:delete_all, _from, state) do
    %State{file_path: path} = state
    binary = :erlang.term_to_binary([])

    :ok = File.write(path, binary)

    {:reply, :ok, state}
  end

  def handle_call({:delete_all_from_grouping, grouping_id}, _from, state) do
    %State{file_path: path} = state
    {:ok, binary} = File.read(path)
    updated_associations = Map.delete(:erlang.binary_to_term(binary), grouping_id)

    :ok = File.write(path, :erlang.term_to_binary(updated_associations))

    {:reply, :ok, state}
  end

  def handle_call({:remove_nodes_from_grouping, grouping_id, nodes}, _from, state) do
    %State{file_path: path} = state
    associations = read_all_associations(path)

    new_associations =
      try do
        Map.update!(associations, grouping_id, fn old_node_ids ->
          old_node_ids -- nodes
        end)
      rescue
        KeyError ->
          :invalid_grouping_id
      end

    case new_associations do
      :invalid_grouping_id = error ->
        {:reply, {:error, error}, state}

      _ ->
        :ok = File.write(path, :erlang.term_to_binary(new_associations))
        {:reply, :ok, state}
    end
  end

  def handle_call({:delete_nodes_from_all_associations, nodes}, _from, state) do
    %State{file_path: path} = state

    associations =
      path
      |> read_all_associations()
      |> Enum.reduce(%{}, fn {grouping_id, ns}, new_associations ->
        Map.put(new_associations, grouping_id, ns -- nodes)
      end)

    write_associations(path, associations)

    {:reply, :ok, state}
  end

  defp try_create_file(path) do
    try do
      write_associations(path, %{})
      {:ok, %State{file_path: path}}
    rescue
      _e ->
        raise ArgumentError, """
        Unable to create the file for associations

        file_path: #{inspect(path)}
        """
    end
  end

  defp write_associations(file_path, associations) do
    binary = :erlang.term_to_binary(associations)
    File.write!(file_path, binary)
  end

  defp read_all_associations(file_path) do
    file_path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
