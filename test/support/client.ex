defmodule Grizzly.Test.Client do
  @behaviour Grizzly.Client

  alias Grizzly.Packet

  def connect(_ip_address, _port) do
    port = :rand.uniform(8_000)

    case :gen_udp.open(port, [:binary, {:active, true}]) do
      {:error, :eacces} -> connect(nil, nil)
      {:ok, socket} -> {:ok, socket}
    end
  end

  def close(socket) do
    :gen_udp.close(socket)
  end

  def send(socket, binary, opts) do
    port = Keyword.fetch!(opts, :port)
    :gen_udp.send(socket, {0, 0, 0, 0}, port, binary)
  end

  def parse_response({:udp, _, _, _, packet}) do
    {:ok, Packet.decode(packet)}
  end

  def send_heart_beat(socket, opts) do
    port = Keyword.fetch!(opts, :port)
    :gen_udp.send(socket, {0, 0, 0, 0}, port, Packet.heart_beat())
  end
end
