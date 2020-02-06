defmodule Grizzly do
  alias Grizzly.Connection

  def send_command(node_id, command) do
    Connection.send_command(node_id, command)
  end
end
