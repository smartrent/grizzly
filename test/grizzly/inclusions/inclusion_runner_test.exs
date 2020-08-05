defmodule Grizzly.Inclusions.InclusionRunnerTest do
  use ExUnit.Case

  alias Grizzly.Inclusions.InclusionRunner
  alias Grizzly.ZWave.Command

  defmodule TestHandler do
    @moduledoc false

    @behaviour Grizzly.InclusionHandler

    alias Grizzly.Report

    @impl Grizzly.InclusionHandler
    def handle_report(%Report{} = report, opts) do
      case report.command.name do
        :node_add_status ->
          send(Keyword.get(opts, :tester), {:test_handler, :called})

        _ ->
          :ok
      end
    end

    @impl Grizzly.InclusionHandler
    def handle_timeout(_, _), do: :ok
  end

  @tag :inclusion
  test "add a node to the network" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 300)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_add_status
    assert Command.param!(report.command, :status) == :done
  end

  @tag :inclusion
  test "add node to network with handler module" do
    {:ok, runner} =
      InclusionRunner.start_link(controller_id: 300, handler: {TestHandler, tester: self()})

    :ok = InclusionRunner.add_node(runner)

    assert_receive {:test_handler, :called}, 600
  end

  @tag :inclusion
  test "start inclusion but then stop it" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 301)
    # start inclusion
    :ok = InclusionRunner.add_node(runner)

    # simulate person waiting and deciding to stop inclusion
    :timer.sleep(500)

    :ok = InclusionRunner.add_node_stop(runner)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_add_status
    assert Command.param!(report.command, :status) == :failed
  end

  @tag :inclusion
  test "removes a node from the Z-Wave network" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 300)
    :ok = InclusionRunner.remove_node(runner)

    :timer.sleep(500)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_remove_status
    assert Command.param!(report.command, :status) == :done
  end

  @tag :inclusion
  test "start exclusion but then stop it" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 301)
    # start inclusion
    :ok = InclusionRunner.remove_node(runner)

    # simulate person waiting and deciding to stop inclusion
    :timer.sleep(500)

    :ok = InclusionRunner.remove_node_stop(runner)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_remove_status
    assert Command.param!(report.command, :status) == :failed
  end

  @tag :inclusion
  test "start s2 inclusion with out keys, adding s2 unauthenticated keys" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 302)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_add_keys_report

    :ok = InclusionRunner.grant_keys(runner, [:s2_unauthenticated])

    assert_receive {:grizzly, :report, next_report}, 1000

    assert next_report.command.name == :node_add_dsk_report
    assert Command.param!(next_report.command, :input_dsk_length) == 0

    :ok = InclusionRunner.set_dsk(runner)

    assert_receive {:grizzly, :report, last_report}, 1000

    assert last_report.command.name == :node_add_status
    assert Command.param!(last_report.command, :status) == :done
    assert Command.param!(last_report.command, :keys_granted) == [:s2_unauthenticated]
  end

  @tag :inclusion
  test "start s2 inclusion with s2 authenticated" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 302)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :node_add_keys_report

    :ok = InclusionRunner.grant_keys(runner, [:s2_authenticated])

    assert_receive {:grizzly, :report, next_report}, 1000

    assert next_report.command.name == :node_add_dsk_report
    assert Command.param!(next_report.command, :input_dsk_length) == 2

    :ok = InclusionRunner.set_dsk(runner, 12345)

    assert_receive {:grizzly, :report, last_report}, 1000

    assert last_report.command.name == :node_add_status
    assert Command.param!(last_report.command, :status) == :done
    assert Command.param!(last_report.command, :keys_granted) == [:s2_authenticated]
  end
end
