defmodule Grizzly.Connection do
  @moduledoc false

  require Logger

  alias Grizzly.Connections.Supervisor
  alias Grizzly.Connections.{AsyncConnection, BinaryConnection, SyncConnection}
  alias Grizzly.Report
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type opt() :: {:mode, Grizzly.connection_mode()} | {:owner, pid()} | {:unnamed, boolean()}

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
  Send a `Grizzly.ZWave.Command` to a Z-Wave device.
  """
  @spec send_command(GenServer.name() | ZWave.node_id(), Command.t(), [Grizzly.command_opt()]) ::
          Grizzly.send_command_response()
  def send_command(node_id, command, opts \\ []) do
    mode = Keyword.get(opts, :mode, :sync)
    Logger.debug("Sending Cmd (#{inspect(mode)}): #{inspect(command)}")

    case mode do
      :sync ->
        # For sync commands, we want to return {:error, :nack_response} to preserve
        # backwards compatibility.
        case SyncConnection.send_command(node_id, command, opts) do
          {:ok, %Grizzly.Report{status: :complete, type: type}}
          when type in [:nack_response, :queue_full] ->
            {:error, type}

          other ->
            other
        end

      :async ->
        # `AsyncConnection.send_command` always returns {:ok, ref}. We'll translate this
        # to a `Grizzly.Report` for consistency with `SyncConnection`'s behavior.
        {:ok, ref} = AsyncConnection.send_command(node_id, command, opts)
        {:ok, Report.new(:inflight, :queued_delay, node_id, command_ref: ref, queued: true)}
    end
  end

  @doc """
  Send a `Grizzly.ZWave.Command` to a Z-Wave device using a specific async connection.
  """
  @spec send_async_command_via(GenServer.name(), ZWave.node_id(), Command.t(), [
          Grizzly.command_opt()
        ]) ::
          Grizzly.send_command_response()
  def send_async_command_via(connection, node_id, command, opts) do
    Logger.debug("Sending Cmd (async via): #{inspect(command)}")
    {:ok, ref} = AsyncConnection.send_command(connection, command, opts)
    {:ok, Report.new(:inflight, :queued_delay, node_id, command_ref: ref, queued: true)}
  end

  def send_binary(node_id, binary, opts \\ []) do
    base = Keyword.get(opts, :format, :hex)
    Logger.debug("Sending binary: #{inspect(binary, base: base)}")

    BinaryConnection.send_binary(node_id, binary)
  end
end
