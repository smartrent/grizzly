defmodule Grizzly.Commands.CommandRunnerTest do
  use ExUnit.Case

  alias Grizzly.SeqNumber
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    NodeListGet,
    NodeListReport,
    SwitchBinaryGet,
    SwitchBinaryReport,
    SwitchBinarySet,
    ZIPPacket
  }

  test "runs a basic application command that only expects an ack response" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    {:ok, runner} = CommandRunner.start_link(command)

    ack_response = ZIPPacket.make_ack_response(CommandRunner.seq_number(runner))

    assert {:complete, :ok} == CommandRunner.handle_zip_command(runner, ack_response)
  end

  test "runs a network command that has the seq number as part of the command" do
    {:ok, command} = NodeListGet.new(seq_number: SeqNumber.get_and_inc())
    {:ok, runner} = CommandRunner.start_link(command)

    command_seq_number = Command.param!(command, :seq_number)

    # ensure that the seq number the command has is used by the command runner
    assert command_seq_number == CommandRunner.seq_number(runner)

    {:ok, node_list_report} =
      NodeListReport.new(
        status: :latest,
        seq_number: command_seq_number,
        controller_id: 1,
        node_ids: []
      )

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(node_list_report, SeqNumber.get_and_inc())

    assert {:complete, {:ok, ^node_list_report}} =
             CommandRunner.handle_zip_command(runner, zip_packet)
  end

  test "runs a basic application command that expects a report" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = CommandRunner.start_link(command)

    {:ok, switch_binary_report} = SwitchBinaryReport.new(target_value: :on)

    {:ok, zip_packet} =
      ZIPPacket.with_zwave_command(switch_binary_report, SeqNumber.get_and_inc())

    assert {:complete, {:ok, ^switch_binary_report}} =
             CommandRunner.handle_zip_command(runner, zip_packet)
  end

  test "runs command that will receive a nack response" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = CommandRunner.start_link(command, retries: 0)

    nack_response = ZIPPacket.make_nack_response(CommandRunner.seq_number(runner))

    assert {:error, :nack_response} == CommandRunner.handle_zip_command(runner, nack_response)
  end

  test "ignores nack_response not for command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = CommandRunner.start_link(command)

    nack_response = ZIPPacket.make_nack_response(CommandRunner.seq_number(runner) + 1)

    assert :continue == CommandRunner.handle_zip_command(runner, nack_response)
  end

  test "handles a queued command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = CommandRunner.start_link(command)

    nack_waiting = ZIPPacket.make_nack_waiting_response(CommandRunner.seq_number(runner), 3)

    assert {:queued, 3} == CommandRunner.handle_zip_command(runner, nack_waiting)
  end

  test "encodes a command" do
    {:ok, command} = SwitchBinaryGet.new()
    {:ok, runner} = CommandRunner.start_link(command)
    seq_number = CommandRunner.seq_number(runner)

    assert <<0x23, 0x02, 0x80, 0x50, seq_number, 0x00, 0x00, 0x25, 0x02>> ==
             CommandRunner.encode_command(runner)
  end

  describe "seq numbering" do
    test "assign a seq number for a command without one" do
      {:ok, command} = SwitchBinaryGet.new()
      {:ok, runner} = CommandRunner.start_link(command)

      assert CommandRunner.seq_number(runner)
    end

    test "use the seq number for a command that has one" do
      {:ok, command} = NodeListGet.new(seq_number: SeqNumber.get_and_inc())
      {:ok, runner} = CommandRunner.start_link(command)
      command_seq_number = Command.param!(command, :seq_number)

      # ensure that the seq number the command has is used by the command runner
      assert command_seq_number == CommandRunner.seq_number(runner)
    end
  end
end
