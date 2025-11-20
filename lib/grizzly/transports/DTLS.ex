defmodule Grizzly.Transports.DTLS do
  @moduledoc """
  DTLS implementation of the `Grizzly.Transport` behaviour
  """

  @behaviour Grizzly.Transport

  alias Grizzly.{Trace, Transport, ZWave}
  require Logger

  @handshake_timeout Application.compile_env(:grizzly, :dtls_handshake_timeout, 10_000)

  @impl Grizzly.Transport
  def open(args, ifaddr \\ {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}) do
    ip_address = Keyword.fetch!(args, :ip_address)
    port = Keyword.fetch!(args, :port)

    node_id =
      case Keyword.fetch!(args, :node_id) do
        :gateway -> 1
        node_id -> node_id
      end

    case :ssl.connect(ip_address, port, dtls_opts(ifaddr), 10_000) do
      {:ok, socket} ->
        {:ok,
         Transport.new(__MODULE__, %{
           socket: socket,
           port: port,
           ip_address: ip_address,
           node_id: node_id
         })}

      {:error, _} = error ->
        error
    end
  end

  @impl Grizzly.Transport
  def send(transport, binary, opts) do
    socket = Transport.get(transport, :socket)

    # `:trace` can explicitly be set to false to disable tracing on a particular
    # command
    if Keyword.get(opts, :trace, true) do
      {:ok, node_id} = Transport.node_id(transport)
      maybe_write_trace(:outgoing, node_id, binary)
    end

    :ssl.send(socket, binary)
  end

  @impl Grizzly.Transport
  def parse_response({:ssl, _socket, binary}, opts) do
    {:ok, node_id} = Transport.node_id(opts[:transport])
    maybe_write_trace(:incoming, node_id, binary)
    parse_zip_packet(binary, opts)
  end

  def parse_response({:ssl_error, _socket, {:tls_alert, {:unexpected_message, _message}}}, _opts) do
    {:ok, :connection_closed}
  end

  def parse_response({:ssl_closed, _socket}, _opts) do
    {:ok, :connection_closed}
  end

  defp parse_zip_packet(binary, opts) do
    if Keyword.get(opts, :raw, false) do
      {:ok, binary}
    else
      ZWave.from_binary(binary)
    end
  end

  @impl Grizzly.Transport
  def close(transport) do
    transport
    |> Transport.get(:socket)
    |> :ssl.close()
  end

  @impl Grizzly.Transport
  def listen(transport) do
    port = Transport.get(transport, :port)
    ip_address = Transport.get(transport, :ip_address)

    # Listen sockets should start in passive mode to avoid undefined behavior.
    # See https://www.erlang.org/doc/apps/ssl/ssl.html#handshake/3
    case :ssl.listen(port, dtls_opts(ip_address, active: false)) do
      {:ok, listening_socket} ->
        {:ok, Transport.put(transport, :socket, listening_socket), strategy: :accept}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def accept(transport) do
    socket = Transport.get(transport, :socket)

    case :ssl.transport_accept(socket) do
      {:ok, socket} ->
        {:ok, Transport.put(transport, :socket, socket)}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def handshake(transport) do
    socket = Transport.get(transport, :socket)

    with {:ok, socket} <- :ssl.handshake(socket, @handshake_timeout),
         :ok <- :ssl.setopts(socket, active: true) do
      {:ok, Transport.put(transport, :socket, socket)}
    end
  end

  @impl Grizzly.Transport
  def peername(transport) do
    socket = Transport.get(transport, :socket)
    :ssl.peername(socket)
  end

  @doc false
  def user_lookup(:psk, _username, user_state) do
    {:ok, user_state}
  end

  defp dtls_opts(ifaddr, opts \\ []) do
    protocol =
      case tuple_size(ifaddr) do
        4 -> :inet
        8 -> :inet6
      end

    [
      protocol,
      :binary,
      {:ssl_imp, :new},
      {:active, Keyword.get(opts, :active, true)},
      {:verify, :verify_none},
      {:versions, [:"dtlsv1.2", :dtlsv1]},
      {:protocol, :dtls},
      {:ciphers, [{:psk, :aes_128_cbc, :sha}]},
      {:psk_identity, ~c"Client_identity"},
      {:user_lookup_fun,
       {&user_lookup/3,
        <<0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78,
          0x90, 0xAA>>}},
      {:cb_info, {:gen_udp, :udp, :udp_close, :udp_error}},
      {:ifaddr, ifaddr},
      {:log_level, :error}
    ]
  end

  defp maybe_write_trace(:incoming, node_id, binary),
    do: Trace.log(binary, src: node_id, dest: :grizzly)

  defp maybe_write_trace(:outgoing, node_id, binary),
    do: Trace.log(binary, src: :grizzly, dest: node_id)
end
