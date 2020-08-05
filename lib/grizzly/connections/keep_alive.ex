defmodule Grizzly.Connections.KeepAlive do
  @moduledoc false

  # module for working with the Z/IP Keep Alive command and handling the keep
  # alive information

  alias Grizzly.{Commands, ZWave}
  alias Grizzly.ZWave.Commands.ZIPKeepAlive

  @type opt :: {:owner, pid()}

  @type t :: %__MODULE__{
          ref: reference() | nil,
          last_send: non_neg_integer() | nil,
          interval: non_neg_integer() | nil,
          owner: pid(),
          command_runner: pid() | nil,
          node_id: ZWave.node_id()
        }

  defstruct ref: nil,
            last_send: nil,
            interval: nil,
            owner: nil,
            command_runner: nil,
            node_id: nil

  @doc """
  Initialize a keep alive timer

  This will start the timer at the given interval and send the message
  `:keep_alive_tick` after that interval has passed
  """
  @spec init(ZWave.node_id(), non_neg_integer(), [opt()]) :: t()
  def init(node_id, interval, opt \\ []) do
    owner = Keyword.get(opt, :owner, self())

    %__MODULE__{
      interval: interval,
      owner: owner,
      node_id: node_id
    }
    |> timer_start()
  end

  @doc """
  Make the Z-Wave command for the keep alive

  This does not send it the command
  """
  @spec make_command(t()) :: t()
  def make_command(keep_alive) do
    {:ok, keep_alive_command} = ZIPKeepAlive.new(ack_flag: :ack_request)
    {:ok, command_runner} = Commands.create_command(keep_alive_command, keep_alive.node_id)

    %__MODULE__{keep_alive | command_runner: command_runner}
  end

  @doc """
  Clears the process timer and stops any currently running command
  """
  @spec timer_clear(t()) :: t()
  def timer_clear(keep_alive) do
    _ = Process.cancel_timer(keep_alive.ref)

    %__MODULE__{keep_alive | ref: nil}
    |> maybe_stop_command_runner()
  end

  @doc """
  Restarts the keep alive

  This will clear the current timer, stop any running command, and start the
  timer again.
  """
  def timer_restart(keep_alive) do
    keep_alive
    |> timer_clear()
    |> timer_start()
  end

  @doc """
  Run the keep alive command with a runner function passed in
  """
  @spec run(t(), (pid() -> :ok)) :: t()
  def run(keep_alive, runner_func) do
    :ok = runner_func.(keep_alive.command_runner)
    %__MODULE__{keep_alive | last_send: :os.system_time(:millisecond)}
  end

  defp timer_start(keep_alive) do
    ref = Process.send_after(keep_alive.owner, :keep_alive_tick, keep_alive.interval)

    %__MODULE__{keep_alive | ref: ref}
  end

  defp maybe_stop_command_runner(%__MODULE__{command_runner: nil} = ka), do: ka

  defp maybe_stop_command_runner(%__MODULE__{command_runner: runner} = ka) when is_pid(runner) do
    :ok = Commands.stop(runner)
    %__MODULE__{ka | command_runner: nil}
  end
end
