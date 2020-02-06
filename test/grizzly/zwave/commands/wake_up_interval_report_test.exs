defmodule Grizzly.ZWave.Commands.WakeUpIntervalReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WakeUpIntervalReport

  test "creates the command and validates params" do
    params = [seconds: 1000, node_id: 1]
    {:ok, _command} = WakeUpIntervalReport.new(params)
  end

  test "encodes params correctly" do
    params = [seconds: 1000, node_id: 1]
    {:ok, command} = WakeUpIntervalReport.new(params)
    expected_binary = <<0x00, 0x03, 0xE8, 0x01>>
    assert expected_binary == WakeUpIntervalReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00, 0x03, 0xE8, 0x01>>
    {:ok, params} = WakeUpIntervalReport.decode_params(binary_params)
    assert Keyword.get(params, :seconds) == 1000
    assert Keyword.get(params, :node_id) == 1
  end
end
