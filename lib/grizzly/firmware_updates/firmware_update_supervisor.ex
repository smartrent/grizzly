defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunnerSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.{FirmwareUpdates, Options}
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    DynamicSupervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc """
  Start a firmware runner process to manage the firmware update
  """
  @spec start_runner([FirmwareUpdates.opt()]) :: DynamicSupervisor.on_start_child()
  def start_runner(opts \\ []) do
    opts = ensure_handler(opts)
    child_spec = FirmwareUpdateRunner.child_spec(opts)
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl DynamicSupervisor
  def init(grizzly_options) do
    # Only one firmware update runner can be running at a time
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_children: 1,
      extra_arguments: [grizzly_options]
    )
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
