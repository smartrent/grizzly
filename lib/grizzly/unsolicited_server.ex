defmodule Grizzly.UnsolicitedServer do
  @moduledoc false
  use GenServer

  require Logger

  alias Grizzly.ZIPGateway
  alias Grizzly.UnsolicitedServer.SocketSupervisor

  defmodule State do
    @moduledoc false
    defstruct ip_address: nil, socket: nil
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %State{ip_address: ZIPGateway.unsolicited_server_ip()}, {:continue, :listen}}
  end

  @impl true
  def handle_continue(:listen, state) do
    case ssl_listen(state.ip_address) do
      {:ok, listensocket} ->
        start_accepting_sockets(listensocket)
        {:noreply, %{state | socket: nil}}

      _error ->
        # wait 2 seconds to try again
        _ = Logger.warn("[Grizzly]: Unsolicited server unable to listen")
        :timer.sleep(2000)
        {:noreply, state, {:continue, :listen}}
    end
  end

  def ssl_listen(ip_address) do
    try do
      :ssl.listen(41230, opts(ip_address))
    rescue
      error -> error
    end
  end

  def start_accepting_sockets(listensocket) do
    Enum.each(1..10, fn _ -> SocketSupervisor.start_socket(listensocket) end)
  end

  def user_lookup(:psk, _username, userstate), do: {:ok, userstate}

  def opts(ip_address) do
    [
      :binary,
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
      ip_version_from_address(ip_address),
      {:ifaddr, ip_address}
    ]
  end

  # move to ZIPPacket
  defp ip_version_from_address({_, _, _, _}), do: :inet
  defp ip_version_from_address({_, _, _, _, _, _, _, _}), do: :inet6
end
