defmodule Grizzly.Requests.RequestRunnerTest do
  use ExUnit.Case

  alias Grizzly.Report
  alias Grizzly.Requests.RequestRunner
  alias Grizzly.SeqNumber
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.NodeListGet
  alias Grizzly.ZWave.Commands.NodeListReport
  alias Grizzly.ZWave.Commands.SwitchBinaryGet
  alias Grizzly.ZWave.Commands.SwitchBinaryReport
  alias Grizzly.ZWave.Commands.SwitchBinarySet
  alias Grizzly.ZWave.Commands.ZIPPacket

  test "runs a basic application command that only expects an ack response" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    {:ok, runner} = RequestRunner.start_link(command, 1)
    ref = RequestRunner.reference(runner)

    ack_response = ZIPPacket.make_ack_response(RequestRunner.seq_number(runner))
    report = Report.new(:complete, :ack_response, 1, command_ref: ref, acknowledged: true)

    assert report == RequestRunner.handle_zip_command(runner, ack_response)
  end

  test "runs a network command that has the seq number as part of the command" do
    {:ok, command} = NodeListGet.new(seq_number: SeqNumber.get_and_inc())
    {:ok, runner} = RequestRunner.start_link(command, 1)
    ref = RequestRunner.reference(runner)

    command_seq_number = Command.param!(command, :seq_number)

    # ensure that the seq number the command has is used by the command runner
    assert command_seq_number == RequestRunner.seq_number(runner)

    {:ok, node_list_report} =
      NodeListReport.new(
        status: :latest,
        seq_number: command_seq_number,
        controller_id: 1,
        node_ids: []
      )

    report = Report.new(:complete, :command, 1, command: node_list_report, command_ref: ref)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(node_list_report, SeqNumber.get_and_inc())

    assert report == RequestRunner.handle_zip_command(runner, zip_packet)
  end

  test "runs a basic application command that expects a report" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1)
    ref = RequestRunner.reference(runner)

    {:ok, switch_binary_report} = SwitchBinaryReport.new(target_value: :on)

    report = Report.new(:complete, :command, 1, command: switch_binary_report, command_ref: ref)

    {:ok, zip_packet} =
      ZIPPacket.with_zwave_command(switch_binary_report, SeqNumber.get_and_inc())

    assert report == RequestRunner.handle_zip_command(runner, zip_packet)
  end

  test "runs command that will receive a nack response" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1, retries: 0)

    nack_response = ZIPPacket.make_nack_response(RequestRunner.seq_number(runner))

    assert %Report{status: :complete, type: :nack_response, node_id: 1} =
             RequestRunner.handle_zip_command(runner, nack_response)
  end

  test "handles :nack_queue_full response" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1, retries: 0)

    {:ok, nack_queue_full} =
      ZIPPacket.new(seq_number: RequestRunner.seq_number(runner), flag: :nack_queue_full)

    assert %Grizzly.Report{status: :complete, type: :queue_full, queued: false} =
             RequestRunner.handle_zip_command(runner, nack_queue_full)

    refute Process.alive?(runner)
  end

  test "ignores nack_response not for command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1)

    nack_response = ZIPPacket.make_nack_response(RequestRunner.seq_number(runner) + 1)

    assert :continue == RequestRunner.handle_zip_command(runner, nack_response)
  end

  test "handles a queued command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1)
    command_ref = RequestRunner.reference(runner)

    nack_waiting = ZIPPacket.make_nack_waiting_response(RequestRunner.seq_number(runner), 3)

    report =
      Report.new(:inflight, :queued_delay, 1,
        queued: true,
        command_ref: command_ref,
        queued_delay: 3
      )

    assert report == RequestRunner.handle_zip_command(runner, nack_waiting)
  end

  test "handles queued complete command" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    {:ok, runner} = RequestRunner.start_link(command, 1)
    command_ref = RequestRunner.reference(runner)

    nack_waiting = ZIPPacket.make_nack_waiting_response(RequestRunner.seq_number(runner), 3)

    assert Report.new(:inflight, :queued_delay, 1,
             queued: true,
             queued_delay: 3,
             command_ref: command_ref
           ) ==
             RequestRunner.handle_zip_command(runner, nack_waiting)

    ack_response = ZIPPacket.make_ack_response(RequestRunner.seq_number(runner))

    report =
      Report.new(:complete, :ack_response, 1,
        queued: true,
        command_ref: command_ref,
        acknowledged: true
      )

    assert report ==
             RequestRunner.handle_zip_command(runner, ack_response)
  end

  @tag :integration
  test "handles queued complete command with long timeout" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    {:ok, runner} = RequestRunner.start_link(command, 1)
    command_ref = RequestRunner.reference(runner)

    nack_waiting = ZIPPacket.make_nack_waiting_response(RequestRunner.seq_number(runner), 2)

    assert Report.new(:inflight, :queued_delay, 1,
             queued_delay: 2,
             queued: true,
             command_ref: command_ref
           ) ==
             RequestRunner.handle_zip_command(runner, nack_waiting)

    Process.sleep(250)

    ack_response = ZIPPacket.make_ack_response(RequestRunner.seq_number(runner))

    assert Report.new(:complete, :ack_response, 1,
             command_ref: command_ref,
             queued: true,
             acknowledged: true
           ) ==
             RequestRunner.handle_zip_command(runner, ack_response)
  end

  test "encodes a command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = RequestRunner.start_link(command, 1)
    seq_number = RequestRunner.seq_number(runner)

    assert <<0x23, 0x02, 0x80, 0x50, seq_number, 0x00, 0x00, 0x25, 0x02>> ==
             RequestRunner.encode_command(runner)
  end

  describe "seq numbering" do
    test "assign a seq number for a command without one" do
      {:ok, command} = SwitchBinaryGet.new()
      {:ok, runner} = RequestRunner.start_link(command, 1)

      assert RequestRunner.seq_number(runner)
    end

    test "use the seq number for a command that has one" do
      {:ok, command} = NodeListGet.new(seq_number: SeqNumber.get_and_inc())
      {:ok, runner} = RequestRunner.start_link(command, 1)
      command_seq_number = Command.param!(command, :seq_number)

      # ensure that the seq number the command has is used by the command runner
      assert command_seq_number == RequestRunner.seq_number(runner)
    end
  end
end
