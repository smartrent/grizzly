defmodule Grizzly.Requests.Handlers.WaitReport do
  @moduledoc """
  This handle is useful for when you want to wait for a particular report from
  the Z-Wave network. Most GET commands can use this handler.
  """
  @behaviour Grizzly.Requests.Handler

  alias Grizzly.ZWave.Command

  @type state :: %{complete_report: atom(), get_command: Command.t()}

  @type opt :: {:complete_report, atom(), get_command: Command.t()}

  @impl Grizzly.Requests.Handler
  def init(command, opts) do
    report_name = Keyword.fetch!(opts, :complete_report)
    {:ok, %{complete_report: report_name, get_command: command}}
  end

  @impl Grizzly.Requests.Handler
  def handle_ack(state), do: {:continue, state}

  @impl Grizzly.Requests.Handler
  def handle_command(command, state) do
    expected? =
      not is_nil(command) and command.name == state.complete_report and
        report_matches_get?(state.get_command, command)

    if state.complete_report == :any or expected? do
      {:complete, command}
    else
      {:continue, state}
    end
  end

  defp report_matches_get?(get, report) do
    if function_exported?(get.impl, :report_matches_get?, 2) do
      get.impl.report_matches_get?(get, report)
    else
      true
    end
  end
end
