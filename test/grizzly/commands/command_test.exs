defmodule Grizzly.Commands.CommandTest do
  use ExUnit.Case, async: true

  alias Grizzly.Report
  alias Grizzly.Commands.Command

  alias Grizzly.ZWave.CommandClasses.ZIP

  alias Grizzly.ZWave.Commands.{
    SwitchBinaryGet,
    SwitchBinaryReport,
    SwitchBinarySet,
    ZIPKeepAlive,
    ZIPPacket
  }

  alias Grizzly.CommandHandlers.AckResponse

  test "turns a Z-Wave command into a Grizzly command" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    expected_grizzly_command = %Command{
      handler: AckResponse,
      handler_state: nil,
      source: zwave_command,
      owner: self(),
      retries: 0,
      seq_number: grizzly_command.seq_number,
      ref: grizzly_command.ref,
      node_id: 1,
      supervision?: false
    }

    assert expected_grizzly_command == grizzly_command
  end

  test "makes the Grizzly command into a binary" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    expected_binary = <<35, 2, 128, 80, grizzly_command.seq_number, 0, 0, 37, 1, 255>>

    assert expected_binary == Command.to_binary(grizzly_command)
  end

  test "handles Z/IP Packet for an ack response" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)

    report =
      Report.new(:complete, :ack_response, 1,
        command_ref: grizzly_command.ref,
        acknowledged: true
      )

    assert {report, %Command{grizzly_command | status: :complete, acknowledged: true}} ==
             Command.handle_zip_command(grizzly_command, ack_response)
  end

  test "handles Z/IP Packet for an report" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    {:ok, switch_report} = SwitchBinaryReport.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)
    {:ok, zip_report} = ZIPPacket.with_zwave_command(switch_report, seq_number: 100)

    report =
      Report.new(:complete, :command, 1, command: switch_report, command_ref: grizzly_command.ref)

    assert {:continue, %Command{}} = Command.handle_zip_command(grizzly_command, ack_response)

    assert {report, %Command{grizzly_command | status: :complete}} ==
             Command.handle_zip_command(grizzly_command, zip_report)
  end

  test "handles Z/IP Packet for queued" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    nack_waiting = ZIPPacket.make_nack_waiting_response(grizzly_command.seq_number, 2)

    report =
      Report.new(:inflight, :queued_delay, 1,
        command_ref: grizzly_command.ref,
        queued_delay: 2,
        queued: true
      )

    assert {report, %Command{grizzly_command | status: :queued}} ==
             Command.handle_zip_command(grizzly_command, nack_waiting)
  end

  test "handles when a queued command is completed" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    grizzly_command = %Command{grizzly_command | status: :queued}

    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)

    report =
      Report.new(:complete, :ack_response, 1,
        command_ref: grizzly_command.ref,
        queued: true,
        acknowledged: true
      )

    assert {report, %Command{grizzly_command | status: :complete, acknowledged: true}} ==
             Command.handle_zip_command(grizzly_command, ack_response)
  end

  test "handles Z/IP Packet for nack response with retries" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self(), retries: 2)

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    expected_new_command = %Command{grizzly_command | retries: grizzly_command.retries - 1}

    assert {:retry, expected_new_command} ==
             Command.handle_zip_command(grizzly_command, nack_response)
  end

  test "handles Z/IP Packet for nack response with no retries" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self(), retries: 0)

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    assert {report, grizzly_command} =
             Command.handle_zip_command(grizzly_command, nack_response)

    assert %Report{status: :complete, type: :nack_response, node_id: 1} = report
    assert grizzly_command.status == :complete
  end

  test "if Z/IP keep alive command, does not encode as a Z/IP Packet" do
    {:ok, keep_alive} = ZIPKeepAlive.new(ack_flag: :ack_request)
    grizzly_command = Command.from_zwave_command(keep_alive, 1, self())
    expected_binary = <<ZIP.byte(), 0x03, 0x80>>

    assert expected_binary == Command.to_binary(grizzly_command)
  end

  test "handle when ZIP command reports stats" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command =
      Command.from_zwave_command(zwave_command, 1, self(), transmission_stats: true)

    ime = [
      {:route_changed, true},
      {:transmit_channel, 4},
      {:transmission_time, 0},
      {:last_working_route, [1001, 1002, 1003, 1004], {9999, :kbit}},
      {:rssi_hops, [-40, -50, -60, :not_available, :not_available]},
      {:local_node_tx_power, -80, :remote_node_tx_power, -90},
      {:local_noise_floor, -85, :remote_noise_floor, -91},
      {:outgoing_rssi_hops, [-40, -50, :max_power_saturated, :not_available, :not_available]}
    ]

    ack_response =
      ZIPPacket.make_ack_response(grizzly_command.seq_number,
        header_extensions: [installation_and_maintenance_report: ime]
      )

    {report, _command} = Command.handle_zip_command(grizzly_command, ack_response)
    transmission_stats = report.transmission_stats

    assert Keyword.get(transmission_stats, :rssi_dbm) == -60
    assert Keyword.get(transmission_stats, :rssi_4bars) == 4
    assert Keyword.get(transmission_stats, :last_working_route) == [1001, 1002, 1003, 1004]
    assert Keyword.get(transmission_stats, :transmission_speed) == {9999, :kbit}
    # ensure filtering of unused transmission stats
    assert Keyword.get(transmission_stats, :local_node_tx_power) == -80
    assert Keyword.get(transmission_stats, :remote_node_tx_power) == -90
    assert Keyword.get(transmission_stats, :local_noise_floor) == -85
    assert Keyword.get(transmission_stats, :remote_noise_floor) == -91

    assert Keyword.get(transmission_stats, :outgoing_rssi_hops) == [
             -40,
             -50,
             :max_power_saturated,
             :not_available,
             :not_available
           ]
  end
end
