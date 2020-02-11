defmodule Grizzly.ZWave.CommandHandlers.WaitReport do
  @moduledoc """
  This handle is useful for when you want to wait for a particular report from
  the Z-Wave network. Most GET commands can use this handler.
  """
  @behaviour Grizzly.ZWave.CommandHandler

  alias Grizzly.ZWave.Command

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
          {:continue, state} | {:complete, {:ok, Command.t()}}
  def handle_command(command, state) do
    if command.name == state.complete_report do
      {:complete, {:ok, command}}
    else
      {:continue, state}
    end
  end
end
