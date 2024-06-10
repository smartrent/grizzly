defmodule Grizzly.ZWave.Commands.SensorMultilevelReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelReport

  test "creates the command and validates params" do
    params = [sensor_type: :temperature, scale: 2, value: 75.5]
    {:ok, _command} = SensorMultilevelReport.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :temperature, scale: 2, value: 75.5]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x01::3, 0x02::2, 0x02::3, 0x02, 0xF3>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    params = [sensor_type: :temperature, scale: 2, value: 75.500000001]
    {:ok, command} = SensorMultilevelReport.new(params)
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    params = [sensor_type: :temperature, scale: 2, value: 214_748_364.711111]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x01::3, 0x02::2, 0x04::3, 0x7F, 0xFF, 0xFF, 0xFF>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    params = [sensor_type: :temperature, scale: 2, value: 2147.48364711111]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x06::3, 0x02::2, 0x04::3, 0x7F, 0xFF, 0xFF, 0xFF>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    params = [sensor_type: :temperature, scale: 2, value: 0.2147483647]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x07::3, 0x02::2, 0x04::3, 0x00, 0x20, 0xC4, 0x9C>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    assert_raise ArgumentError, fn ->
      params = [sensor_type: :temperature, scale: 2, value: 2_147_483_647 + 1]
      {:ok, command} = SensorMultilevelReport.new(params)
      SensorMultilevelReport.encode_params(command)
    end

    params = [sensor_type: :temperature, scale: 2, value: 2_147_483_647 + 0.1]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x00::3, 0x02::2, 0x04::3, 0x7F, 0xFF, 0xFF, 0xFF>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)

    assert_raise ArgumentError, fn ->
      params = [sensor_type: :temperature, scale: 2, value: 2_147_483_647 + 0.5]
      {:ok, command} = SensorMultilevelReport.new(params)
      expected_binary = <<0x01, 0x00::3, 0x02::2, 0x04::3, 0x7F, 0xFF, 0xFF, 0xFF>>
      assert expected_binary == SensorMultilevelReport.encode_params(command)
    end
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x01::3, 0x02::2, 0x02::3, 0x02, 0xF3>>
    {:ok, params} = SensorMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
    assert Keyword.get(params, :scale) == 2
    assert Keyword.get(params, :value) == 75.5
  end
end
