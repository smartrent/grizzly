defmodule Grizzly.Connection do
  require Logger

  alias Grizzly.Connections.Supervisor
  alias Grizzly.Connections.{SyncConnection, AsyncConnection}

  def open(node_id, opts \\ []) do
    Logger.warn("asdfjaklsjdfklasjdlfkjalskdjflasjdlfjalskdjflasja #{inspect(node_id)}")
    Supervisor.start_connection(node_id, opts)
  end

  def send_command(node_id, command, opts \\ []) do
    Logger.warn("Sending: #{inspect(command)}")

    case Keyword.get(opts, :type, :sync) do
      :sync ->
        SyncConnection.send_command(node_id, command, opts)

      :async ->
        AsyncConnection.send_command(node_id, command, opts)
    end
  end
end
