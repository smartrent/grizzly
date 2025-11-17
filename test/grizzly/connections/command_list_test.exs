defmodule Grizzly.Connections.CommandListTest do
  use ExUnit.Case, async: true

  alias Grizzly.Connections.CommandList
  alias Grizzly.Report
  alias Grizzly.Requests.RequestRunner
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, SwitchBinarySet, ZIPPacket}

  test "create and monitor a command runtime" do
    {:ok, zwave_command} = SwitchBinaryGet.new()

    {:ok, runner, _ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self())

    assert is_pid(runner)
    assert CommandList.get_waiter_for_runner(command_list, runner) == self()
  end

  test "response for complete" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    {:ok, runner, ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self())

    ack_response = ZIPPacket.make_ack_response(RequestRunner.seq_number(runner))

    report = Report.new(:complete, :ack_response, 1, command_ref: ref, acknowledged: true)

    assert {self(), {report, CommandList.empty()}} ==
             CommandList.response_for_zip_packet(command_list, ack_response)
  end

  test "response for nack response" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    {:ok, runner, _ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self(), retries: 0)

    ack_response = ZIPPacket.make_nack_response(RequestRunner.seq_number(runner))

    pid = self()

    assert {^pid, {report, %CommandList{}}} =
             CommandList.response_for_zip_packet(command_list, ack_response)

    assert %Report{status: :complete, type: :nack_response, node_id: 1} = report

    refute Process.alive?(runner)
  end

  test "response for queued" do
    {:ok, zwave_command} = SwitchBinaryGet.new()

    {:ok, runner, ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self())

    queued_response = ZIPPacket.make_nack_waiting_response(RequestRunner.seq_number(runner), 3)

    report =
      Report.new(:inflight, :queued_delay, 1, command_ref: ref, queued: true, queued_delay: 3)

    assert {self(), {report, command_list}} ==
             CommandList.response_for_zip_packet(command_list, queued_response)

    assert Process.alive?(runner)
  end

  test "response for retry" do
    {:ok, zwave_command} = SwitchBinaryGet.new()

    {:ok, runner, _ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self(), retries: 2)

    nack_response = ZIPPacket.make_nack_response(RequestRunner.seq_number(runner))

    assert {:retry, runner, command_list} ==
             CommandList.response_for_zip_packet(command_list, nack_response)

    assert Process.alive?(runner)
  end

  test "response for continue" do
    {:ok, zwave_command} = SwitchBinaryGet.new()

    {:ok, runner, _ref, command_list} =
      CommandList.create(CommandList.empty(), zwave_command, 1, self())

    ack_response = ZIPPacket.make_ack_response(RequestRunner.seq_number(runner))

    assert {:continue, command_list} ==
             CommandList.response_for_zip_packet(command_list, ack_response)

    assert Process.alive?(runner)
  end
end
