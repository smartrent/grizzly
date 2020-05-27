defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunnerSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.FirmwareUpdates
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec start_runner([FirmwareUpdates.opt()]) :: DynamicSupervisor.on_start_child()
  def start_runner(opts \\ []) do
    opts = Keyword.merge([handler: self()], opts)
    child_spec = FirmwareUpdateRunner.child_spec(opts)
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    # Only one firmware update runner can be running at a time
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
  end
end
