defmodule Grizzly.Storage.Populate do
  @moduledoc false

  # Populates storage at startup by reading relevant info from Z/IP Gateway's
  # database.

  use GenServer, restart: :temporary

  alias Grizzly.Storage
  alias Grizzly.ZIPGateway.Database, as: ZIPGatewayDb
  alias Grizzly.ZWave.DSK

  require Logger

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    database = Keyword.get(opts, :database, Grizzly.options().database_file)

    cond do
      Keyword.get(opts, :disabled) != false and
          Application.get_env(:grizzly, __MODULE__, [])[:disabled] == true ->
        :ignore

      not is_reference(database) and (not is_binary(database) or not File.exists?(database)) ->
        :ignore

      Storage.get(["migrated_zipgateway_db"]) == true ->
        :ignore

      true ->
        GenServer.start_link(__MODULE__, [database: database], name: __MODULE__)
    end
  end

  @impl GenServer
  def init(opts) do
    {:ok, %{database: opts[:database]}, {:continue, :populate}}
  end

  @impl GenServer
  def handle_continue(:populate, state) do
    result =
      ZIPGatewayDb.with_database(state.database, fn db ->
        with {:ok, nodes} <- ZIPGatewayDb.all_nodes(db),
             {:ok, endpoints} <- ZIPGatewayDb.all_endpoints(db) do
          endpoints_by_node = Enum.group_by(endpoints, & &1.node_id)

          nodes_with_endpoints =
            Enum.map(nodes, fn node ->
              Map.put(node, :endpoints, Map.get(endpoints_by_node, node.id, []))
            end)

          {:ok, nodes_with_endpoints}
        end
      end)

    nodes =
      case result do
        {:ok, nodes} -> nodes
        {:error, _reason} -> []
      end

    populate_storage(nodes)

    Storage.put(["migrated_zipgateway_db"], true)

    {:stop, :normal, state}
  end

  defp populate_storage([%{id: 1} | rest]), do: populate_storage(rest)

  defp populate_storage([node | rest]) do
    populate_node(node)
    populate_storage(rest)
  end

  defp populate_storage([]), do: :ok

  defp populate_node(node) do
    ep_info =
      case Enum.find(node.endpoints, &(&1.id == 0)) do
        nil ->
          %{generic_device_class: nil, specific_device_class: nil, command_classes: []}

        ep ->
          %{
            generic_device_class: ep.generic_device_class,
            specific_device_class: ep.specific_device_class,
            command_classes: ep.command_classes
          }
      end

    listening? = Keyword.get(node.mode, :mode) in [:wakeup, :wakeup_firmware_upgrade]

    node_info =
      Map.merge(
        %{
          listening?: listening?,
          basic_device_class: node.basic_device_class
        },
        ep_info
      )

    Storage.put_node_info(node.id, node_info)
    if listening?, do: Storage.put_node_wakeup_interval(node.id, node.wake_up_interval)
    if is_struct(node.dsk, DSK), do: Storage.put_node_dsk(node.id, node.dsk)
    # rescue
    #   err ->
    #     Logger.error(
    #       "[Grizzly] Error while populating storage from ZGW db for node #{node.id}: #{inspect(err)}"
    #     )
  end
end
