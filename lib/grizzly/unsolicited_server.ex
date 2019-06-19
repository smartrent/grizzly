defmodule Grizzly.UnsolicitedServer do
  use GenServer
  require Logger

  alias Grizzly.UnsolicitedServer.Config
  alias Grizzly.UnsolicitedServer.Socket.Supervisor, as: SocketSupervisor

  defmodule State do
    defstruct config: nil, socket: nil
  end

  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    send(self(), :listen)
    {:ok, %State{config: config}}
  end

  def handle_info(
        :listen,
        %State{config: %Config{ip_address: ip_address, ip_version: ip_version}} = state
      ) do
    case :ssl.listen(41230, opts(ip_address, ip_version)) do
      {:ok, listensocket} ->
        _ = Logger.info("[GRIZZLY]: unsolicited server waiting for connections")
        start_accepting_sockets(listensocket)
        {:noreply, %{state | socket: nil}}

      error ->
        _ =
          Logger.warn(
            "[GRIZZLY]: Unable to bind unsolicited messages server. Error: #{inspect(error)}"
          )

        Process.send_after(self(), :listen, 2_000)
        {:noreply, state}
    end
  end

  def start_accepting_sockets(listensocket) do
    Enum.each(1..10, fn _ -> SocketSupervisor.start_socket(listensocket) end)
  end

  def user_lookup(:psk, _username, userstate), do: {:ok, userstate}

  def opts(ip_address, ip_version) do
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
      ip_version,
      {:ifaddr, ip_address}
    ]
  end
end
