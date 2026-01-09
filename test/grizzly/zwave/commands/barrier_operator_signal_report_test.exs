defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.BarrierOperatorSignalReport

  test "creates the command and validates params" do
    params = [subsystem_type: :audible_notification, subsystem_state: :on]
    {:ok, _command} = Commands.create(:barrier_operator_signal_report, params)
  end

  test "encodes params correctly" do
    params = [subsystem_type: :audible_notification, subsystem_state: :on]
    {:ok, command} = Commands.create(:barrier_operator_signal_report, params)
    expected_binary = <<0x01, 0xFF>>
    assert expected_binary == BarrierOperatorSignalReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x00>>
    {:ok, params} = BarrierOperatorSignalReport.decode_params(binary_params)
    assert Keyword.get(params, :subsystem_type) == :visual_notification
    assert Keyword.get(params, :subsystem_state) == :off
  end
end
