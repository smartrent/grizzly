defmodule Grizzly.Client.DTLS do
  @type dtls_socket_message ::
          {:ssl, :ssl.sslsocket(), [char()] | binary} | {:ssl_closed, :ssl.sslsocket()}
  @moduledoc """
  A DTLS client to be used with Grizzly.
  """
  @behaviour Grizzly.Client

  alias Grizzly.{Client, Packet}

  @spec close(:ssl.sslsocket()) :: :ok
  def close(socket) do
    :ok = :ssl.close(socket)
  end

  @spec connect(:inet.socket_address(), :inet.port_number()) :: {:ok, :ssl.sslsocket()}
  def connect(server_ip, server_port) do
    opts =
      server_ip
      |> get_ip_version()
      |> opts()

    :ssl.connect(server_ip, server_port, opts, 10_000)
  end

  @spec send(Client.socket(), binary, keyword) :: :ok
  def send(socket, binary, _opts) do
    :ssl.send(socket, binary)
  end

  @spec parse_response(dtls_socket_message()) ::
          {:ok, :heart_beat | Packet.t()} | {:error, :socket_closed}
  def parse_response({:ssl, {:sslsocket, {:gen_udp, _, :dtls_connection}, _}, packet}) do
    packet =
      packet
      |> :binary.list_to_bin()
      |> Packet.decode()
      |> Packet.log()

    case Packet.heart_beat_response(packet) do
      true -> {:ok, :heart_beat}
      false -> {:ok, packet}
    end
  end

  def parse_response({:ssl_closed, {:sslsocket, {:gen_udp, _, :dtls_connection}, _}}) do
    {:error, :socket_closed}
  end

  @spec send_heart_beat(Client.socket(), keyword) :: :ok
  def send_heart_beat(socket, _opts) do
    :ssl.send(socket, Packet.heart_beat())
  end

  defp opts(ip_version) do
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
      ip_version
    ]
  end

  def user_lookup(:psk, _username, userstate) do
    {:ok, userstate}
  end

  defp get_ip_version({_, _, _, _}), do: :inet
  defp get_ip_version({_, _, _, _, _, _, _, _}), do: :inet6
end
