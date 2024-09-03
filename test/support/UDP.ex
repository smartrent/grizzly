defmodule GrizzlyTest.Transport.UDP do
  @moduledoc false

  @behaviour Grizzly.Transport

  alias Grizzly.{Transport, ZWave}
  alias Grizzly.Transport.Response

  @test_host {0, 0, 0, 0}
  @test_port 5_000

  @impl Grizzly.Transport
  def open(args) do
    case Keyword.get(args, :ip_address) do
      {0, 0, 0, 600} ->
        {:error, :timeout}

      {0, 0, 0, node_id} ->
        {:ok, socket} = :gen_udp.open(@test_port + node_id, [:binary, {:active, true}])
        {:ok, Transport.new(__MODULE__, %{socket: socket, node_id: node_id})}
    end
  end

  @impl Grizzly.Transport
  def listen(transport), do: {:ok, transport, strategy: :none}

  @impl Grizzly.Transport
  def accept(transport) do
    {:ok, transport}
  end

  @impl Grizzly.Transport
  def handshake(transport), do: {:ok, transport}

  @impl Grizzly.Transport
  def send(transport, binary, _) do
    node_id = Transport.assign(transport, :node_id)
    Grizzly.Trace.log(binary, src: :grizzly, dest: node_id)

    transport
    |> Transport.assign(:socket)
    |> :gen_udp.send(@test_host, @test_port, binary)
  end

  @impl Grizzly.Transport
  def peername(transport) do
    socket = Transport.assign(transport, :socket)
    :inet.peername(socket)
  end

  @impl Grizzly.Transport
  def parse_response({:udp, _, ip, _port, binary}, opts) do
    transport = Keyword.fetch!(opts, :transport)
    node_id = Transport.assign(transport, :node_id)
    Grizzly.Trace.log(binary, src: node_id, dest: :grizzly)

    if Keyword.get(opts, :raw, false) do
      {:ok, binary}
    else
      case ZWave.from_binary(binary) do
        {:ok, command} ->
          {:ok, %Response{ip_address: ip, command: command}}

        {:error, _type} = error ->
          error
      end
    end
  end

  @impl Grizzly.Transport
  def close(transport) do
    transport
    |> Transport.assign(:socket)
    |> :gen_udp.close()
  end
end
