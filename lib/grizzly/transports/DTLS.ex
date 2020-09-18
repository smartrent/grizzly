defmodule Grizzly.Transports.DTLS do
  @moduledoc false

  @behaviour Grizzly.Transport

  alias Grizzly.ZWave

  require Logger

  @impl true
  def open(ip_address, port) do
    case :ssl.connect(ip_address, port, dtls_opts(), 10_000) do
      {:ok, _socket} = result -> result
      {:error, _} = error -> error
    end
  end

  @impl true
  def send(socket, binary) do
    :ssl.send(socket, binary)
  end

  @impl true
  def parse_response({:ssl, {:sslsocket, {:gen_udp, _, :dtls_connection}, _}, bin_list}) do
    binary = :erlang.list_to_binary(bin_list)

    # TODO: handle errors
    {:ok, _result} = result = ZWave.from_binary(binary)
    result
  end

  @impl true
  def close(socket) do
    :ssl.close(socket)
  end

  def user_lookup(:psk, _username, userstate) do
    {:ok, userstate}
  end

  defp dtls_opts() do
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
      :inet6
    ]
  end
end
