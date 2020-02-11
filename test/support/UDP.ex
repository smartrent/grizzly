defmodule GrizzlyTest.Transport.UDP do
  @behaviour Grizzly.Transport

  alias Grizzly.ZWave.Commands.ZIPPacket

  @test_host {0, 0, 0, 0}
  @test_port 5_000

  @impl true
  def open({0, 0, 0, 600}, _port), do: {:error, :timeout}

  def open({0, 0, 0, node_id}, _port) do
    case :gen_udp.open(@test_port + node_id, [:binary, {:active, true}]) do
      {:ok, socket} -> {:ok, socket}
    end
  end

  @impl true
  def send(socket, binary) do
    :gen_udp.send(socket, @test_host, @test_port, binary)
  end

  @impl true
  def parse_response({:udp, _, _, _, binary}) do
    case ZIPPacket.from_binary(binary) do
      {:ok, _zip_packet} = result -> result
    end
  end

  @impl true
  def close(socket) do
    :gen_udp.close(socket)
  end
end
