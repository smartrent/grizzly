defmodule Grizzly.Connection do
  @moduledoc false

  require Logger

  alias Grizzly.Connections.Supervisor
  alias Grizzly.Connections.{BinaryConnection, SyncConnection, AsyncConnection}
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type opt() :: {:mode, :sync | :async | :binary} | {:owner, pid()}

  @doc """
  Open a connection to a node or the Z/IP Gateway

  If the DTLS connection cannot be opened after some time this will return
  `{:error, :timeout}`
  """
  @spec open(ZWave.node_id() | :gateway, [opt()]) :: {:ok, pid()} | {:error, :timeout}
  def open(node_id, opts \\ []) do
    Supervisor.start_connection(node_id, opts)
  end

  @doc """
  Close a connection to a Z-Wave node
  """
  @spec close(ZWave.node_id()) :: :ok
  def close(node_id) do
    # only close sync connections because async connections
    # are only used during inclusion and are short lived. Also,
    # in Grizzly.send_command/4 we wont allow sending anything during
    # an inclusion so anything that would want a connection closed would
    # not hit this point unless there a bug. So, lets assume that
    # this is only valid for sync connections. If this assumption is false
    # we should get really active errors that a user can share in a bug
    # report to help us identify how the assumption is false and we can
    # explore fixing that.
    SyncConnection.close(node_id)
  end

  @doc """
  Send a `Grizzly.ZWave.Command` to a Z-Wave device
  """
  @spec send_command(ZWave.node_id(), Command.t(), [Grizzly.command_opt()]) ::
          Grizzly.send_command_response()
  def send_command(node_id, command, opts \\ []) do
    _ = Logger.debug("Sending Cmd: #{inspect(command)}")

    case Keyword.get(opts, :type, :sync) do
      :sync ->
        SyncConnection.send_command(node_id, command, opts)

      :async ->
        AsyncConnection.send_command(node_id, command, opts)
    end
  end

  def send_binary(node_id, binary, opts \\ []) do
    base = Keyword.get(opts, :format, :hex)
    _ = Logger.debug("Sending binary: #{inspect(binary, base: base)}")

    BinaryConnection.send_binary(node_id, binary)
  end
end
