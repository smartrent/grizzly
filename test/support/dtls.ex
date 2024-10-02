defmodule GrizzlyTest.Transport.DTLS do
  @moduledoc """
  DTLS implementation of the `Grizzly.Transport` behaviour
  """

  @behaviour Grizzly.Transport

  alias Grizzly.Transport
  require Logger

  @handshake_timeout Application.compile_env(:grizzly, :dtls_handshake_timeout, 10_000)

  @impl Grizzly.Transport
  def open(args) do
    args = Keyword.put(args, :ip_address, {127, 0, 0, 1})

    with {:ok, transport} <- Grizzly.Transports.DTLS.open(args, {127, 0, 0, 1}),
         socket = Transport.get(transport, :socket),
         node_id = Transport.get(transport, :node_id),
         :ok <- :ssl.send(socket, <<node_id::16>>) do
      transport = Transport.put(transport, :type, :client)
      {:ok, transport}
    end
  end

  @impl Grizzly.Transport
  defdelegate send(transport, binary, opts), to: Grizzly.Transports.DTLS

  @impl Grizzly.Transport
  defdelegate parse_response(response, opts), to: Grizzly.Transports.DTLS

  @impl Grizzly.Transport
  defdelegate close(transport), to: Grizzly.Transports.DTLS

  @impl Grizzly.Transport
  def listen(transport) do
    with {:ok, transport, opts} <- Grizzly.Transports.DTLS.listen(transport) do
      transport = Transport.put(transport, :type, :server)
      {:ok, transport, opts}
    end
  end

  @impl Grizzly.Transport
  defdelegate accept(transport), to: Grizzly.Transports.DTLS
  @impl Grizzly.Transport
  defdelegate peername(transport), to: Grizzly.Transports.DTLS

  @impl Grizzly.Transport
  def handshake(transport) do
    socket = Transport.get(transport, :socket)

    with {:ok, socket} <- :ssl.handshake(socket, @handshake_timeout),
         {:ok, transport} <- receive_node_id(transport),
         :ok <- :ssl.setopts(socket, active: true) do
      {:ok, Transport.put(transport, :socket, socket)}
    end
  end

  defp receive_node_id(transport) do
    if Transport.get(transport, :type) == :server do
      socket = Transport.get(transport, :socket)

      with {:ok, node_id} when is_list(node_id) <- :ssl.recv(socket, 2, 1000) do
        <<node_id::16>> = :erlang.list_to_binary(node_id)
        {:ok, Transport.put(transport, :node_id, node_id)}
      end
    else
      transport
    end
  end
end
