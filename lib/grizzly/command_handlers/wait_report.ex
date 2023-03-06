defmodule Grizzly.CommandHandlers.WaitReport do
  @moduledoc """
  This handle is useful for when you want to wait for a particular report from
  the Z-Wave network. Most GET commands can use this handler.
  """
  @behaviour Grizzly.CommandHandler

  alias Grizzly.ZWave.Command

  require Logger

  @type state :: %{complete_report: atom()}

  @type opt :: {:complete_report, atom()}

  @spec init([opt]) :: {:ok, state()}
  def init(opts) do
    report_name = Keyword.fetch!(opts, :complete_report)
    {:ok, %{complete_report: report_name}}
  end

  @spec handle_ack(state()) :: {:continue, state()}
  def handle_ack(state), do: {:continue, state}

  @spec handle_command(Command.t(), state()) ::
          {:continue, state} | {:complete, Command.t()}
  def handle_command(command, state) do
    if state.complete_report == :any or command.name == state.complete_report do
      {:complete, command}
    else
      if command.name == :application_busy,
        do: wait_application_busy(command)

      {:continue, state}
    end
  end

  defp wait_application_busy(command) do
    status = Keyword.get(command.params, :status)
    wait_time_secs = Keyword.get(command.params, :wait_time, 1)

    delay =
      case status do
        :try_again_later -> 500
        :try_again_after_wait -> wait_time_secs * 1_000
        :request_queued -> 0
      end

    Logger.warn("[Grizzly] Application busy - waiting #{delay} msecs")
    :timer.sleep(delay)
  end
end
