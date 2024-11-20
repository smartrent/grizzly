defmodule Grizzly.UnsolicitedServer.DTLSTransport do
  @moduledoc false

  @behaviour ThousandIsland.Transport

  # Dialyzer complains about the `:ciphers` option passed to `:ssl.listen/2`
  # even though the option works as passed (and is required).
  @dialyzer {:no_return, listen: 2, do_listen: 3}

  @impl ThousandIsland.Transport
  def listen(port, opts), do: do_listen(port, opts, 3)

  @impl ThousandIsland.Transport
  defdelegate accept(listener_socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate handshake(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate controlling_process(socket, pid), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate recv(socket, length, timeout), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate send(socket, data), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate getopts(socket, options), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate setopts(socket, options), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate shutdown(socket, way), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate close(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate sockname(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate peername(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate peercert(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate getstat(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate negotiated_protocol(socket), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate secure?, to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate sendfile(socket, file, offset, length), to: ThousandIsland.Transports.SSL
  @impl ThousandIsland.Transport
  defdelegate upgrade(socket, options), to: ThousandIsland.Transports.SSL

  defp user_lookup(:psk, _username, userstate) do
    {:ok, userstate}
  end

  defp do_listen(port, opts, attempts) do
    ifaddr = Keyword.fetch!(opts, :ifaddr)

    protocol =
      case tuple_size(ifaddr) do
        4 -> :inet
        8 -> :inet6
      end

    listen_opts = [
      protocol,
      {:mode, :binary},
      {:active, false},
      {:verify, :verify_none},
      {:versions, [:"dtlsv1.2", :dtlsv1]},
      {:protocol, :dtls},
      {:ciphers, [{:psk, :aes_128_cbc, :sha}]},
      {:psk_identity, ~c"Client_identity"},
      {:user_lookup_fun,
       {&user_lookup/3,
        <<0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56, 0x78,
          0x90, 0xAA>>}},
      {:ifaddr, ifaddr},
      {:log_level, :error}
    ]

    case :ssl.listen(port, listen_opts) do
      {:ok, listener} ->
        {:ok, listener}

      {:error, _} when attempts > 0 ->
        :timer.sleep(1000)
        do_listen(port, opts, attempts - 1)

      {:error, _} = err ->
        err
    end
  end
end
