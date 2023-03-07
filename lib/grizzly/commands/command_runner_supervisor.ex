defmodule Grizzly.Commands.CommandRunnerSupervisor do
  @moduledoc false

  # Supervisor for command runners

  use DynamicSupervisor

  alias Grizzly.Commands.{Command, CommandRunner}
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a new supervised runtime for a command
  """
  @spec start_runner(ZWaveCommand.t(), ZWave.node_id(), [Command.opt()]) ::
          DynamicSupervisor.on_start_child()
  def start_runner(command, node_id, command_opts) do
    command_opts = Keyword.merge([owner: self()], command_opts)
    child_spec = CommandRunner.child_spec([command, node_id, command_opts])

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
