defmodule Grizzly.ZWave.Commands.WakeUpIntervalSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.WakeUpIntervalSetReport

  test "creates the command and validates params" do
    params = [seconds: 1000, node_id: 1]
    {:ok, _command} = Commands.create(:wake_up_interval_set, params)
  end

  test "encodes params correctly" do
    params = [seconds: 1000, node_id: 1]
    {:ok, command} = Commands.create(:wake_up_interval_set, params)
    expected_binary = <<0x00, 0x03, 0xE8, 0x01>>
    assert expected_binary == WakeUpIntervalSetReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00, 0x03, 0xE8, 0x01>>
    {:ok, params} = WakeUpIntervalSetReport.decode_params(binary_params)
    assert Keyword.get(params, :seconds) == 1000
    assert Keyword.get(params, :node_id) == 1
  end
end
