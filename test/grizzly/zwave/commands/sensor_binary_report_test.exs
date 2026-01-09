defmodule Grizzly.ZWave.Commands.SensorBinaryReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SensorBinaryReport

  test "creates the command and validates params" do
    params = [triggered: true]
    {:ok, _command} = Commands.create(:sensor_binary_report, params)
  end

  test "encodes v1 params correctly" do
    params = [triggered: true]
    {:ok, command} = Commands.create(:sensor_binary_report, params)
    expected_binary = <<0xFF>>
    assert expected_binary == SensorBinaryReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0x00>>
    {:ok, params} = SensorBinaryReport.decode_params(binary_params)
    assert Keyword.get(params, :triggered) == false
  end

  test "encodes v2 params correctly" do
    params = [sensor_type: :door_window, triggered: true]
    {:ok, command} = Commands.create(:sensor_binary_report, params)
    expected_binary = <<0xFF, 0x0A>>
    assert expected_binary == SensorBinaryReport.encode_params(command)
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x00, 0x0A>>
    {:ok, params} = SensorBinaryReport.decode_params(binary_params)
    assert Keyword.get(params, :sensor_type) == :door_window
    assert Keyword.get(params, :triggered) == false
  end
end
