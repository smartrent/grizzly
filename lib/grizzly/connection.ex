defmodule Grizzly.Connection do
  @moduledoc false

  alias Grizzly.Connection.Socket
  alias Grizzly.ZWaveCommand

  @type socket_opt ::
          {:transport, module()} | {:host, :inet.ip_address()} | {:port, :inet.port_number()}

  @spec open(non_neg_integer(), [socket_opt]) :: :ok
  def open(node_id, opts \\ []) do
    # TODO: Supervisor this!
    {:ok, socket} = Socket.start_link(node_id, opts)

    :ok = Socket.open(socket)

    :ok
  end

  @spec send_command(non_neg_integer(), Grizzly.ZWaveCommand.t()) :: :ok | {:ok, any()}
  def send_command(node_id, command) do
    Socket.send(node_id, command)
  end

  @spec close(non_neg_integer()) :: :ok
  def close(node_id) do
    Socket.close(node_id)
  end
end
