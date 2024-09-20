defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunnerTest do
  use ExUnit.Case
  use Mimic.DSL

  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport
  alias GrizzlyTest.Utils

  setup :set_mimic_global

  @tag :firmware_update
  test "request that a device begin a firmware update" do
    image_path = "test/serialapi_controller_bridge_OTW_SD3503_US.gbl"

    {:ok, runner} =
      FirmwareUpdateRunner.start_link(
        Utils.default_options(),
        device_id: 300,
        manufacturer_id: 1
      )

    :ok = FirmwareUpdateRunner.start_firmware_update(runner, image_path)
    assert_receive {:grizzly, :report, received_command}, 500
    assert received_command.name == :firmware_update_md_request_report
  end

  @tag :firmware_update
  test "request that a device updates its firmware" do
    Grizzly.Trace.clear()

    node_id = 201
    image_path = "test/serialapi_controller_bridge_OTW_SD3503_US.gbl"

    {:ok, runner} =
      FirmwareUpdateRunner.start_link(
        Utils.default_options(),
        max_fragment_size: 30,
        device_id: node_id,
        manufacturer_id: 1,
        transmission_delay: 1
      )

    Process.monitor(runner)

    :ok = FirmwareUpdateRunner.start_firmware_update(runner, image_path)

    assert_receive {:grizzly, :report, received_command}
    assert received_command.name == :firmware_update_md_request_report

    assert_receive {:grizzly, :report, get_command}
    assert get_command.name == :firmware_update_md_get

    # Let everything finish
    Process.sleep(500)

    runner_state = :sys.get_state(runner)
    assert 6 == runner_state.fragment_index

    [frag5_attempt_1, nack_response, frag5_attempt_2, ack_response] =
      Enum.slice(Grizzly.Trace.list(), -4..-1//1)

    assert 5 ==
             frag5_attempt_1.binary
             |> Grizzly.ZWave.from_binary()
             |> elem(1)
             |> Command.param!(:command)
             |> Command.param!(:report_number)

    assert :nack_response ==
             nack_response.binary
             |> Grizzly.ZWave.from_binary()
             |> elem(1)
             |> Command.param!(:flag)

    assert 5 ==
             frag5_attempt_2.binary
             |> Grizzly.ZWave.from_binary()
             |> elem(1)
             |> Command.param!(:command)
             |> Command.param!(:report_number)

    assert :ack_response ==
             ack_response.binary
             |> Grizzly.ZWave.from_binary()
             |> elem(1)
             |> Command.param!(:flag)

    {:ok, cmd} = FirmwareUpdateMDStatusReport.new(status: :successful_restarting)

    send(
      runner,
      {:grizzly, :report, Grizzly.Report.new(:complete, :command, node_id, command: cmd)}
    )

    assert_receive {:grizzly, :report, status_command}
    assert status_command.name == :firmware_update_md_status_report

    assert_receive {:DOWN, _ref, :process, ^runner, :normal}
  end
end
