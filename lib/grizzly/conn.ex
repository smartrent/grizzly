defmodule Grizzly.Conn do
  alias Grizzly.Command
  alias Grizzly.Conn.Config
  alias Grizzly.Conn.Supervisor, as: ConnSupervisor
  alias Grizzly.Conn.Server, as: ConnServer

  @type t :: %__MODULE__{
          conn: pid,
          ip_address: :inet.ip_address(),
          mode: Config.mode()
        }

  @enforce_keys [:conn]
  defstruct conn: nil, ip_address: nil, mode: nil

  @spec open(Config.t()) :: t
  def open(conn_config) do
    {:ok, conn} = ConnSupervisor.start_child(conn_config)
    %__MODULE__{conn: conn, ip_address: conn_config.ip, mode: conn_config.mode}
  end

  @spec send_command(t, Command.t(), Keyword.t()) ::
          :ok | {:ok, any} | {:ok, :queued, reference} | {:error, any}
  def send_command(conn, command, opts \\ []) do
    ConnServer.send_command(conn, command, opts)
  end

  @spec connected?(t) :: boolean
  def connected?(%__MODULE__{conn: conn}) do
    ConnServer.connected?(conn)
  end

  @spec close(t) :: :ok
  def close(%__MODULE__{conn: conn}) do
    :ok = ConnServer.close(conn)
    :ok = ConnSupervisor.stop_connection_server(conn)
  end

  @doc "Override the mode set in the config of the Conn.Server referenced by Conn conn"
  @spec override_mode(t, Config.mode()) :: t
  def override_mode(conn, mode) when mode in [:async, :sync] do
    %__MODULE__{conn | mode: mode}
  end
end
