defmodule Grizzly.Conn.Server do
  @moduledoc false
  use GenServer

  require Logger
  alias Grizzly.Packet
  alias Grizzly.Command.EncodeError
  alias Grizzly.{Notifications, Command, Conn}
  alias Grizzly.Conn.Config

  @retry_connect_delay 1_000

  @type t :: pid

  defmodule State do
    @moduledoc false

    @type command :: %{
            from: GenServer.from(),
            # the owner of queued commands, to which responses are to be sent
            owner: pid,
            command: Command.t(),
            mode: Config.mode(),
            status: :active | :queued,
            queued_ref: nil | reference()
          }

    @type t :: %__MODULE__{
            connected?: boolean,
            socket: :inet.socket(),
            config: Config.t(),
            heart_beat_interval: reference,
            last_command_at: pos_integer,
            commands: [command]
          }

    defstruct connected?: false,
              socket: nil,
              config: nil,
              heart_beat_interval: nil,
              last_command_at: nil,
              commands: []

    def build_command(command, from, mode, opts) do
      %{
        command: command,
        from: from,
        owner: opts[:owner],
        mode: mode,
        status: :active,
        queued_ref: nil
      }
    end
  end

  def child_spec(args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}}
  end

  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @doc """
  Check to see if the connection has been establish
  """
  @spec connected?(pid) :: boolean
  def connected?(conn) do
    GenServer.call(conn, :connected?)
  end

  @spec send_command(Conn.t(), Command.t(), Keyword.t()) ::
          :ok | {:ok, any} | {:error, EncodeError.t() | any()}
  def send_command(%Conn{conn: conn_server, mode: mode}, command, opts) do
    GenServer.call(conn_server, {:send_command, command, mode, opts}, 120_000)
  end

  @doc """
  Close the connection
  """
  def close(conn) do
    GenServer.call(conn, :close)
  end

  @impl true
  def init(config) do
    Kernel.send(self(), :setup)
    {:ok, %State{config: config}}
  end

  @impl true
  def handle_call(:connected?, _from, %State{socket: nil} = state) do
    {:reply, false, state}
  end

  def handle_call(:connected?, _from, %State{socket: _socket} = state) do
    {:reply, true, state}
  end

  def handle_call(:close, _, %State{socket: socket, config: config} = state) do
    :ok = apply(config.client, :close, [socket])
    {:reply, :ok, state}
  end

  def handle_call(
        {:send_command, command, :sync, opts},
        from,
        %State{commands: commands} = state
      ) do
    case do_send_command(command, state) do
      :ok ->
        command = State.build_command(command, from, :sync, opts)
        {:noreply, %{state | last_command_at: now(), commands: commands ++ [command]}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:send_command, command, :async, opts},
        from,
        %State{commands: commands} = state
      ) do
    :ok = do_send_command(command, state)
    command = State.build_command(command, from, :async, opts)

    {:reply, :ok, %{state | last_command_at: now(), commands: commands ++ [command]}}
  end

  @impl true
  def handle_info(:setup, %State{config: config} = state) do
    case maybe_autoconnect(config) do
      {:ok, socket} ->
        _ = Logger.info("connected to: #{inspect(config.ip, base: :hex)}")
        heart_beat_timer = heart_beat(config)
        {:noreply, %{state | socket: socket, last_command_at: now(), heart_beat_interval: heart_beat_timer}}

      :noop ->
        {:noreply, state}

      {:error, :timeout} ->
        _ =
          Logger.warn(
            "[GRIZZLY] Setup autoconnect timed out. Retrying in #{@retry_connect_delay}"
          )

        Process.send_after(self(), :setup, @retry_connect_delay)
        {:noreply, state}
    end
  end

  def handle_info(:heart_beat, %State{config: config, socket: socket} = state) do
    now = now()
    if now - state.last_command_at >= config.heart_beat_timer do
      apply(config.client, :send_heart_beat, [socket, [port: config.port]])
      heart_beat_timer = heart_beat(config)
      {:noreply, %{state | last_command_at: now, heart_beat_interval: heart_beat_timer}}
    else
      heart_beat_timer = heart_beat(config)
      {:noreply, %{state | heart_beat_interval: heart_beat_timer}}
    end
  end

  def handle_info(
        data,
        %State{config: config, commands: commands, connected?: connected?} = state
      ) do
    case apply(config.client, :parse_response, [data]) do
      {:ok, :heart_beat} ->
        if !connected? do
          Notifications.broadcast(:connection_established, config)
          {:noreply, %{state | connected?: true}}
        else
          {:noreply, state}
        end

      {:ok, packet} ->
        if Packet.ack_request?(packet) do
          do_send_raw(Packet.as_ack_response(packet.seq_number), state)
          {:noreply, state}
        else
          commands = process_commands(commands, packet, state)

          {:noreply, %{state | commands: commands}}
        end

      {:error, :socket_closed} ->
        _ = Logger.info("[GATEWAY]: Socket closed reconnecting")
        _ = Process.cancel_timer(state.heart_beat_timer)
        Kernel.send(self(), :setup)
        {:noreply, %{state | connected?: false, heart_beat_timer: nil}}
    end
  end

  defp heart_beat(%Config{heart_beat_timer: timer}) do
    Process.send_after(self(), :heart_beat, timer)
  end

  defp maybe_autoconnect(%Config{autoconnect: false}), do: :noop

  defp maybe_autoconnect(%Config{client: client, ip: ip, port: port}) do
    _ = Logger.info("Attempting to connect to: #{inspect(ip, base: :hex)}")
    apply(client, :connect, [ip, port])
  end

  defp do_send_command(command, %State{config: config, socket: socket}) do
    case Command.encode(command) do
      {:ok, binary} ->
        client_opts = [ip_address: config.ip, port: config.port]
        apply(config.client, :send, [socket, binary, client_opts])

      {:error, _} = error ->
        error
    end
  end

  defp do_send_raw(binary, %State{config: config, socket: socket}) do
    client_opts = [ip_address: config.ip, port: config.port]
    apply(config.client, :send, [socket, binary, client_opts])
  end

  defp process_commands(commands, packet, state) do
    commands
    |> Enum.reduce(
      [],
      fn %{from: {pid, _ref} = sender, command: command, mode: mode} = cmd, acc ->
        # Process managing the command may be gone (e.g. after a timeout)
        if Process.alive?(command) do
          case Command.handle_response(command, packet) do
            {:finished, response} ->
              send_response(cmd, response)

              :ok = Command.complete(command)
              acc

            {:send_message, message} ->
              case mode do
                :sync ->
                  GenServer.reply(sender, message)

                :async ->
                  send(pid, {:async_command, message})
              end

              acc ++ [cmd]

            :retry ->
              do_send_command(command, state)
              acc ++ [cmd]

            :continue ->
              acc ++ [cmd]

            :queued ->
              new_cmd = handle_queued(cmd)
              acc ++ [new_cmd]
          end
        else
          acc
        end
      end
    )
  end

  defp handle_queued(%{status: :queued} = cmd), do: cmd

  defp handle_queued(%{status: :active, mode: :sync, from: from} = cmd) do
    ref = make_ref()
    :ok = GenServer.reply(from, {:ok, :queued, ref})

    %{cmd | status: :queued, queued_ref: ref}
  end

  defp handle_queued(%{status: :active, mode: :aync, from: {pid, _}} = cmd) do
    ref = make_ref()
    :ok = send(pid, {:ok, :queued, ref})

    %{cmd | status: :queued, queued_ref: ref}
  end

  defp send_response(
         %{status: :queued, queued_ref: ref, from: {pid, _}, owner: owner},
         response
       ) do
    message = {Grizzly, :queued_response, ref, response}
    receiver = owner || pid

    _ =
      Logger.info("[GRIZZLY] Sending queued response #{inspect(message)} to #{inspect(receiver)}")

    send(receiver, {Grizzly, :queued_response, ref, response})
  end

  defp send_response(%{status: :active, from: {pid, _}, mode: :async}, response) do
    send(pid, {:async_command, response})
  end

  defp send_response(%{status: :active, from: from, mode: :sync}, response) do
    GenServer.reply(from, response)
  end

  defp now, do: :os.system_time(:millisecond)
end
