defmodule Grizzly.Requests.Handlers.AggregateReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.Requests.Handlers.AggregateReport
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  test "when the waiting report has no reports to follow" do
    {:ok, state} =
      AggregateReport.init(nil, complete_report: :association_report, aggregate_param: :nodes)

    {:ok, association_report} =
      Commands.create(
        :association_report,
        grouping_identifier: 1,
        max_nodes_supported: 5,
        reports_to_follow: 0,
        nodes: [1, 2]
      )

    {:complete, association_report_complete} =
      AggregateReport.handle_command(association_report, state)

    assert Command.param!(association_report_complete, :nodes) == [1, 2]
  end

  test "when the waiting report is aggregated" do
    {:ok, state} =
      AggregateReport.init(nil, complete_report: :association_report, aggregate_param: :nodes)

    {:ok, association_report_one} =
      Commands.create(
        :association_report,
        grouping_identifier: 1,
        max_nodes_supported: 5,
        reports_to_follow: 1,
        nodes: [1, 2]
      )

    {:continue, new_state} = AggregateReport.handle_command(association_report_one, state)

    {:ok, association_report_two} =
      Commands.create(
        :association_report,
        grouping_identifier: 1,
        max_nodes_supported: 5,
        reports_to_follow: 0,
        nodes: [5, 6]
      )

    {:complete, association_report_complete} =
      AggregateReport.handle_command(association_report_two, new_state)

    assert Command.param!(association_report_complete, :nodes) == [1, 2, 5, 6]
  end

  test "when the waiting report has reports to follow" do
    {:ok, state} =
      AggregateReport.init(nil, complete_report: :association_report, aggregate_param: :nodes)

    {:ok, association_report} =
      Commands.create(
        :association_report,
        grouping_identifier: 1,
        max_nodes_supported: 5,
        reports_to_follow: 1,
        nodes: [1, 2]
      )

    expected_state = Map.put(state, :aggregates, [1, 2])

    assert {:continue, expected_state} ==
             AggregateReport.handle_command(association_report, state)
  end

  test "when different report is being handled than the one that is being waited on" do
    {:ok, state} =
      AggregateReport.init(nil, complete_report: :association_report, aggregate_param: :nodes)

    {:ok, switch_binary_report} = Commands.create(:switch_binary_report, target_value: :on)

    assert {:continue, state} == AggregateReport.handle_command(switch_binary_report, state)
  end
end
