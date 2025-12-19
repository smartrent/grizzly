defmodule Grizzly.Requests.RequestRunnerSupervisor do
  @moduledoc false

  # Supervisor for request runners

  use DynamicSupervisor

  alias Grizzly.Requests.Request
  alias Grizzly.Requests.RequestRunner
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a new supervised runtime for a command
  """
  @spec start_runner(ZWaveCommand.t(), ZWave.node_id(), [Request.opt()]) ::
          DynamicSupervisor.on_start_child()
  def start_runner(command, node_id, command_opts) do
    command_opts = Keyword.merge([owner: self()], command_opts)
    child_spec = RequestRunner.child_spec([command, node_id, command_opts])

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
