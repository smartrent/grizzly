defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedReport

  test "creates the command and validates params" do
    params = [subsystem_types: [:audible_notification, :visual_notification]]
    {:ok, _command} = BarrierOperatorSignalSupportedReport.new(params)
  end

  test "encodes params correctly" do
    params = [subsystem_types: [:audible_notification, :visual_notification]]
    {:ok, command} = BarrierOperatorSignalSupportedReport.new(params)
    expected_binary = <<0x03>>
    assert expected_binary == BarrierOperatorSignalSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x03>>
    {:ok, params} = BarrierOperatorSignalSupportedReport.decode_params(binary_params)
    subsystem_types = Keyword.get(params, :subsystem_types, [])
    assert :audible_notification in subsystem_types
    assert :visual_notification in subsystem_types
  end
end
