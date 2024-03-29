defmodule Grizzly.StatusReporter.Console do
  @moduledoc """
  A console status logger which is used by default
  """

  @behaviour Grizzly.StatusReporter

  require Logger

  @impl Grizzly.StatusReporter
  def ready() do
    Logger.info("[Grizzly] Z-Wave is ready to use!")
  end

  @impl Grizzly.StatusReporter
  def zwave_firmware_update_status(status) do
    Logger.info("[Grizzly] Z-Wave module firmware update status: #{inspect(status)}")
  end

  @impl Grizzly.StatusReporter
  def serial_api_status(status) do
    level =
      case status do
        :unresponsive -> :error
        _ -> :info
      end

    Logger.log(level, "[Grizzly] Z-Wave Serial API status: #{inspect(status)}")
  end
end
