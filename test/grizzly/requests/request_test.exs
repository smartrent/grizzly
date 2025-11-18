defmodule Grizzly.Requests.RequestTest do
  use ExUnit.Case, async: true

  alias Grizzly.Report
  alias Grizzly.Requests.Request

  alias Grizzly.ZWave.CommandClasses.ZIP

  alias Grizzly.ZWave.Commands.{
    SwitchBinaryGet,
    SwitchBinaryReport,
    SwitchBinarySet,
    ZIPKeepAlive,
    ZIPPacket
  }

  alias Grizzly.Requests.Handlers.AckResponse

  test "turns a Z-Wave command into a Grizzly request" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    request = Request.from_zwave_command(zwave_command, 1, self())

    expected_request = %Request{
      handler: AckResponse,
      handler_state: nil,
      source: zwave_command,
      owner: self(),
      retries: 0,
      seq_number: request.seq_number,
      ref: request.ref,
      node_id: 1,
      supervision?: false
    }

    assert expected_request == request
  end

  test "makes the Grizzly command into a binary" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    request = Request.from_zwave_command(zwave_command, 1, self())
    expected_binary = <<35, 2, 128, 80, request.seq_number, 0, 0, 37, 1, 255>>

    assert expected_binary == Request.to_binary(request)
  end

  test "handles Z/IP Packet for an ack response" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    request = Request.from_zwave_command(zwave_command, 1, self())

    ack_response = ZIPPacket.make_ack_response(request.seq_number)

    report =
      Report.new(:complete, :ack_response, 1,
        command_ref: request.ref,
        acknowledged: true
      )

    assert {report, %Request{request | status: :complete, acknowledged: true}} ==
             Request.handle_zip_command(request, ack_response)
  end

  test "handles Z/IP Packet for an report" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    {:ok, switch_report} = SwitchBinaryReport.new(target_value: :on)

    request = Request.from_zwave_command(zwave_command, 1, self())
    ack_response = ZIPPacket.make_ack_response(request.seq_number)
    {:ok, zip_report} = ZIPPacket.with_zwave_command(switch_report, seq_number: 100)

    report =
      Report.new(:complete, :command, 1, command: switch_report, command_ref: request.ref)

    assert {:continue, %Request{}} = Request.handle_zip_command(request, ack_response)

    assert {report, %Request{request | status: :complete}} ==
             Request.handle_zip_command(request, zip_report)
  end

  test "handles Z/IP Packet for queued" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    request = Request.from_zwave_command(zwave_command, 1, self())

    nack_waiting = ZIPPacket.make_nack_waiting_response(request.seq_number, 2)

    report =
      Report.new(:inflight, :queued_delay, 1,
        command_ref: request.ref,
        queued_delay: 2,
        queued: true
      )

    assert {report, %Request{request | status: :queued}} ==
             Request.handle_zip_command(request, nack_waiting)
  end

  test "handles when a queued command is completed" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    request = Request.from_zwave_command(zwave_command, 1, self())
    request = %Request{request | status: :queued}

    ack_response = ZIPPacket.make_ack_response(request.seq_number)

    report =
      Report.new(:complete, :ack_response, 1,
        command_ref: request.ref,
        queued: true,
        acknowledged: true
      )

    assert {report, %Request{request | status: :complete, acknowledged: true}} ==
             Request.handle_zip_command(request, ack_response)
  end

  test "handles Z/IP Packet for nack response with retries" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    request = Request.from_zwave_command(zwave_command, 1, self(), retries: 2)

    nack_response = ZIPPacket.make_nack_response(request.seq_number)

    expected_new_command = %Request{request | retries: request.retries - 1}

    assert {:retry, expected_new_command} ==
             Request.handle_zip_command(request, nack_response)
  end

  test "handles Z/IP Packet for nack response with no retries" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    request = Request.from_zwave_command(zwave_command, 1, self(), retries: 0)

    nack_response = ZIPPacket.make_nack_response(request.seq_number)

    assert {report, request} =
             Request.handle_zip_command(request, nack_response)

    assert %Report{status: :complete, type: :nack_response, node_id: 1} = report
    assert request.status == :complete
  end

  test "if Z/IP keep alive command, does not encode as a Z/IP Packet" do
    {:ok, keep_alive} = ZIPKeepAlive.new(ack_flag: :ack_request)
    request = Request.from_zwave_command(keep_alive, 1, self())
    expected_binary = <<ZIP.byte(), 0x03, 0x80>>

    assert expected_binary == Request.to_binary(request)
  end

  test "handle when ZIP command reports stats" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    request =
      Request.from_zwave_command(zwave_command, 1, self(), transmission_stats: true)

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
      ZIPPacket.make_ack_response(request.seq_number,
        header_extensions: [installation_and_maintenance_report: ime]
      )

    {report, _command} = Request.handle_zip_command(request, ack_response)
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
