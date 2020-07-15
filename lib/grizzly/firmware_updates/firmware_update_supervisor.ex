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
    opts = ensure_handler(opts)
    child_spec = FirmwareUpdateRunner.child_spec(opts)
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    # Only one firmware update runner can be running at a time
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
  end

  defp ensure_handler(opts) do
    Keyword.put_new_lazy(opts, :handler, &get_firmware_update_handler/0)
  end

  defp get_firmware_update_handler() do
    case Application.get_env(:girzzly, :handlers) do
      nil ->
        self()

      handlers ->
        Map.get(handlers, :firmware_update, self())
    end
  end
end
