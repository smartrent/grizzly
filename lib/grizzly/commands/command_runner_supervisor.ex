defmodule Grizzly.Commands.CommandRunnerSupervisor do
  @moduledoc false

  # Supervisor for command runners

  use DynamicSupervisor

  alias Grizzly.ZWave.Command, as: ZWaveCommand
  alias Grizzly.Commands.{CommandRunner, Command}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a new supervised runtime for a command
  """
  @spec start_runner(ZWaveCommand.t(), [Command.opt()]) :: DynamicSupervisor.on_start_child()
  def start_runner(command, command_opts) do
    command_opts = Keyword.merge([owner: self()], command_opts)
    child_spec = CommandRunner.child_spec([command, command_opts])

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
