defmodule Grizzly.Inclusions do
  @moduledoc """
  Docs about adding and removing nodes
  """

  alias Grizzly.Inclusions.InclusionRunnerSupervisor
  alias Grizzly.Inclusions.InclusionRunner

  @doc """
  Start the process to add a Z-Wave node to the network
  """
  @spec add_node() :: :ok
  def add_node() do
    case InclusionRunnerSupervisor.start_runner() do
      {:ok, runner} ->
        InclusionRunner.add_node(runner)
    end
  end

  @doc """
  Start the process to remove a Z-Wave node from the network
  """
  @spec remove_node() :: :ok
  def remove_node() do
    case InclusionRunnerSupervisor.start_runner() do
      {:ok, runner} ->
        InclusionRunner.remove_node(runner)
    end
  end

  @doc """
  Check to see if there is an inclusion process running
  """
  @spec inclusion_running?() :: boolean()
  def inclusion_running?() do
    child_count = DynamicSupervisor.count_children(InclusionRunnerSupervisor)
    child_count.active == 1
  end
end
