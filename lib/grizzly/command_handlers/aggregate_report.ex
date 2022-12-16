defmodule Grizzly.CommandHandlers.AggregateReport do
  @moduledoc """
  Handler for working with reports that could take many report frames to
  complete

  This handler will handle aggregating the responses into one report command
  for ease of consumption by callers.
  """
  @behaviour Grizzly.CommandHandler

  alias Grizzly.ZWave.Command

  @type state :: %{complete_report: atom(), aggregate_param: atom(), aggregates: [any()]}

  @type opt :: {:complete_report, atom(), aggregate_param: atom()}

  @spec init([opt]) :: {:ok, state()}
  def init(opts) do
    report_name = Keyword.fetch!(opts, :complete_report)
    aggregate_param = Keyword.fetch!(opts, :aggregate_param)

    {:ok, %{complete_report: report_name, aggregate_param: aggregate_param, aggregates: []}}
  end

  @spec handle_ack(state()) :: {:continue, state()}
  def handle_ack(state), do: {:continue, state}

  @spec handle_command(Command.t(), state()) ::
          {:continue, state} | {:complete, {:ok, Command.t()}}
  def handle_command(command, state) do
    if command.name == state.complete_report do
      do_handle_command(command, state)
    else
      {:continue, state}
    end
  end

  defp aggregate(command, state) do
    %{aggregate_param: aggregate_param, aggregates: aggregates} = state

    new_aggregate_values = Command.param!(command, aggregate_param)

    %{state | aggregates: do_aggregate(aggregates, new_aggregate_values)}
  end

  defp prepare_aggregate_data(command, state) do
    %{aggregate_param: aggregate_param, aggregates: aggregates} = state
    final_values = Command.param!(command, aggregate_param)

    Command.put_param(command, aggregate_param, do_aggregate(aggregates, final_values))
  end

  defp do_aggregate(aggregates, new_aggregate_values) when is_list(aggregates),
    do: aggregates ++ new_aggregate_values

  defp do_aggregate(aggregates, new_aggregate_values) when is_binary(aggregates),
    do: aggregates <> new_aggregate_values

  defp do_handle_command(command, state) do
    rtf = Command.param!(command, :reports_to_follow)

    if rtf == 0 do
      {:complete, prepare_aggregate_data(command, state)}
    else
      {:continue, aggregate(command, state)}
    end
  end
end
