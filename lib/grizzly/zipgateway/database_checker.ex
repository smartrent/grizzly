defmodule Grizzly.ZIPGateway.DatabaseChecker do
  @moduledoc """
  Does some sanity checking on the Z/IP Gateway SQLite database during its init,
  then exits normally.

  Most importantly, it looks for nodes (other than 1) that have no records in the
  endpoints table. This can happen due to a rare bug that's difficult to reproduce,
  but the result is that Z/IP Gateway goes into an infinite loop at startup and
  never recovers. If it finds any such nodes, it will delete them and let Z/IP Gateway
  re-interview them. This unfortunately results in the loss of the DSK, if stored,
  but that's better than having things not work at all.
  """

  use GenServer, restart: :temporary

  require Logger

  alias Grizzly.ZIPGateway.Database, as: ZIPGatewayDb

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    database_file = Keyword.get(opts, :database_file, "/data/zipgateway.db")
    Logger.info("[Grizzly] Running Z/IP Gateway db integrity checks")

    case ZIPGatewayDb.with_database(database_file, &check_node_endpoints/1) do
      :ok ->
        Logger.info("[Grizzly] Z/IP Gateway db integrity checks complete")

      {:error, reason} ->
        Logger.error(
          "[Grizzly] Error running Z/IP Gateway db integrity checks: #{inspect(reason)}"
        )
    end

    :ignore
  rescue
    e ->
      Logger.error("[Grizzly] Error running Z/IP Gateway db integrity checks: #{inspect(e)}")
      :ignore
  end

  defp check_node_endpoints(db) do
    case ZIPGatewayDb.find_nodes_with_no_endpoints(db) do
      {:ok, rows} ->
        node_ids = Enum.map(rows, & &1["nodeid"])

        if node_ids != [] do
          Logger.warning("[Grizzly] Deleting node(s) with no endpoints: #{inspect(node_ids)}")
        end

        Enum.each(node_ids, fn node_id ->
          case ZIPGatewayDb.delete_node(db, node_id) do
            :ok ->
              :ok

            {:error, reason} ->
              Logger.error("[Grizzly] Error deleting node #{node_id}: #{inspect(reason)}")
          end
        end)

      {:error, reason} ->
        Logger.error("[Grizzly] Error checking node endpoints: #{inspect(reason)}")
    end
  end
end
