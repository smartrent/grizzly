defmodule Grizzly.Transports.DTLS do
  @moduledoc """
  DTLS implementation of the `Grizzly.Transport` behaviour
  """

  @behaviour Grizzly.Transport

  alias Grizzly.{Transport, ZWave}
  alias Grizzly.Transport.Response

  require Logger

  @impl Grizzly.Transport
  def open(args) do
    ip_address = Keyword.fetch!(args, :ip_address)
    port = Keyword.fetch!(args, :port)
    ifaddr = {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}

    case :ssl.connect(ip_address, port, dtls_opts(ifaddr), 10_000) do
      {:ok, socket} ->
        {:ok, Transport.new(__MODULE__, %{socket: socket, port: port})}

      {:error, _} = error ->
        error
    end
  end

  @impl Grizzly.Transport
  def send(transport, binary, _) do
    socket = Transport.assign(transport, :socket)
    :ssl.send(socket, binary)
  end

  @impl Grizzly.Transport
  # Erlang/OTP <= 23.1.x
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {_, {{ip, _}, _}}, :dtls_connection}, _}, bin_list},
        opts
      ) do
    binary = :erlang.list_to_binary(bin_list)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok,
         %Response{
           ip_address: ip,
           command: command
         }}
    end
  end

  # Erlang/OTP >= 23.2
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {{ip, _}, _}, :dtls_gen_connection}, _}, bin_list},
        opts
      ) do
    handle_ssl_message_with_ip(ip, bin_list, opts)
  end

  # Erlang/OTP >= 23.2
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {_, {{ip, _}, _}}, :dtls_gen_connection}, _}, bin_list},
        opts
      ) do
    handle_ssl_message_with_ip(ip, bin_list, opts)
  end

  def parse_response({:ssl, {:sslsocket, {:gen_udp, _port, :dtls_connection}, _}, bin_list}, opts) do
    binary = :erlang.list_to_binary(bin_list)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok,
         %Response{
           command: command
         }}
    end
  end

  def parse_response({:ssl_closed, _}, _opts) do
    {:ok, :connection_closed}
  end

  defp handle_ssl_message_with_ip(ip, binary_list, opts) do
    binary = :erlang.list_to_binary(binary_list)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok, %Response{ip_address: ip, command: command}}
    end
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
    |> Transport.assign(:socket)
    |> :ssl.close()
  end

  @impl Grizzly.Transport
  def listen(transport) do
    port = Transport.assign(transport, :port)
    ip_address = Transport.assign(transport, :ip_address)

    case :ssl.listen(port, dtls_opts(ip_address)) do
      {:ok, listening_socket} ->
        {:ok, Transport.assigns(transport, :socket, listening_socket), strategy: :accept}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def accept(transport) do
    socket = Transport.assign(transport, :socket)

    case :ssl.transport_accept(socket) do
      {:ok, socket} ->
        {:ok, Transport.assigns(transport, :accept_socket, socket)}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def handshake(transport) do
    accept_socket = Transport.assign(transport, :accept_socket)

    case :ssl.handshake(accept_socket) do
      {:ok, _handshake_socket} ->
        {:ok, transport}

      error ->
        error
    end
  end

  @doc false
  def user_lookup(:psk, _username, userstate) do
    {:ok, userstate}
  end

  defp dtls_opts(ifaddr) do
    [
      {:ssl_imp, :new},
      {:active, true},
      {:verify, :verify_none},
      {:versions, [:dtlsv1]},
      {:protocol, :dtls},
      {:ciphers, [{:psk, :aes_128_cbc, :sha}]},
      {:psk_identity, 'Client_identity'},
      {:user_lookup_fun,
       {&user_lookup/3,
        <<0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78,
          0x90, 0xAA>>}},
      {:cb_info, {:gen_udp, :udp, :udp_close, :udp_error}},
      :inet6,
      {:ifaddr, ifaddr}
    ]
  end
end
