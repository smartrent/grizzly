defmodule Grizzly.Transports.DTLS do
  @moduledoc """
  DTLS implementation of the `Grizzly.Transport` behaviour
  """

  @behaviour Grizzly.Transport

  alias Grizzly.{Trace, Transport, TransportError, ZWave}
  alias Grizzly.Transport.Response

  @grizzly_ip :inet.ntoa({0xFD00, 0xAAAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02})
  @grizzly_port 41230

  @impl Grizzly.Transport
  def open(args) do
    ip_address = Keyword.fetch!(args, :ip_address)
    port = Keyword.fetch!(args, :port)
    ifaddr = {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}

    case :ssl.connect(ip_address, port, dtls_opts(ifaddr), 10_000) do
      {:ok, socket} ->
        {:ok, Transport.new(__MODULE__, %{socket: socket, port: port, ip_address: ip_address})}

      {:error, _} = error ->
        error
    end
  end

  @impl Grizzly.Transport
  def send(transport, binary, opts) do
    socket = Transport.assign(transport, :socket)

    # `:trace` can explicitly be set to false to disable tracing on a particular
    # command
    if Keyword.get(opts, :trace, true) do
      ip = Transport.assign(transport, :ip_address, "")
      port = Transport.assign(transport, :port)
      maybe_write_trace(:outgoing, ip, port, binary)
    end

    :ssl.send(socket, binary)
  end

  @impl Grizzly.Transport
  # Erlang/OTP <= 23.1.x
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {_, {{ip, port}, _}}, :dtls_connection}, _}, bin_list},
        opts
      ) do
    binary = :erlang.list_to_binary(bin_list)

    maybe_write_trace(:incoming, ip, port, binary)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok,
         %Response{
           ip_address: ip,
           command: command
         }}

      error ->
        error
    end
  end

  # Erlang/OTP >= 23.2
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {{ip, port}, _}, :dtls_gen_connection}, _}, bin_list},
        opts
      ) do
    handle_ssl_message_with_ip(ip, port, bin_list, opts)
  end

  # Erlang/OTP >= 23.2
  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, {_, {{ip, port}, _}}, :dtls_gen_connection}, _}, bin_list},
        opts
      ) do
    handle_ssl_message_with_ip(ip, port, bin_list, opts)
  end

  def parse_response(
        {:ssl, {:sslsocket, {:gen_udp, _erlang_port, :dtls_connection}, _}, bin_list},
        opts
      ) do
    transport = Keyword.get(opts, :transport)
    binary = :erlang.list_to_binary(bin_list)

    {:ok, {ip, port}} = get_sockname(transport)

    maybe_write_trace(:incoming, ip, port, binary)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok,
         %Response{
           command: command
         }}

      error ->
        error
    end
  end

  def parse_response({:ssl_error, _, {:tls_alert, {:unexpected_message, message}}}, _opts) do
    message =
      if is_binary(message) && String.printable?(message) do
        message
      else
        inspect(message, limit: 500)
      end

    raise TransportError, "TLS Alert (unexpected_message): #{message}"
  end

  def parse_response({:ssl_closed, _}, _opts) do
    {:ok, :connection_closed}
  end

  defp get_sockname(nil) do
    {:ok, {"unk", "unk"}}
  end

  defp get_sockname(transport) do
    socket = Transport.assign(transport, :socket)
    :ssl.sockname(socket)
  end

  defp handle_ssl_message_with_ip(ip, port, binary_list, opts) do
    binary = :erlang.list_to_binary(binary_list)
    maybe_write_trace(:incoming, ip, port, binary)

    case parse_zip_packet(binary, opts) do
      {:ok, bin} when is_binary(bin) ->
        {:ok, bin}

      {:ok, command} ->
        {:ok, %Response{ip_address: ip, command: command}}

      error ->
        error
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
        {:ok, Transport.assigns(transport, :socket, socket)}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def handshake(transport) do
    socket = Transport.assign(transport, :socket)

    case :ssl.handshake(socket) do
      {:ok, socket} ->
        {:ok, Transport.assigns(transport, :socket, socket)}

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
      {:versions, [:"dtlsv1.2", :dtlsv1]},
      {:protocol, :dtls},
      {:ciphers, [{:psk, :aes_128_cbc, :sha}]},
      {:psk_identity, ~c"Client_identity"},
      {:user_lookup_fun,
       {&user_lookup/3,
        <<0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78,
          0x90, 0xAA>>}},
      {:cb_info, {:gen_udp, :udp, :udp_close, :udp_error}},
      :inet6,
      {:ifaddr, ifaddr},
      {:log_level, :error}
    ]
  end

  defp maybe_write_trace(in_or_out, ip, port, binary) do
    ip_port_str = make_ip_port_str(ip, port)
    grizzly_ip_port_string = "[#{@grizzly_ip}]:#{@grizzly_port}"

    case in_or_out do
      :incoming ->
        Trace.log(binary, src: ip_port_str, dest: grizzly_ip_port_string)

      :outgoing ->
        Trace.log(binary, src: grizzly_ip_port_string, dest: ip_port_str)
    end
  end

  defp make_ip_port_str("", port) do
    ":#{port}"
  end

  defp make_ip_port_str(ip, port) when is_binary(ip) do
    "[#{ip}]:#{port}"
  end

  defp make_ip_port_str(ip, port) do
    "[#{:inet.ntoa(ip)}]:#{port}"
  end
end
