defmodule Grizzly.ZWave.Commands.MeterReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MeterReport

  test "creates the command and validates params" do
    params = [meter_type: :electric, scale: :kwh, value: 1.25]
    {:ok, _command} = MeterReport.new(params)
  end

  test "encodes params correctly" do
    params = [meter_type: :electric, scale: :kwh, value: 1.25]
    {:ok, command} = MeterReport.new(params)
    expected_binary = <<0x01, 0x02::size(3), 0x00::size(2), 0x01::size(3), 0x7D>>
    assert expected_binary == MeterReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x02::size(3), 0x00::size(2), 0x01::size(3), 0x7D>>
    {:ok, params} = MeterReport.decode_params(binary_params)
    assert Keyword.get(params, :meter_type) == :electric
    assert Keyword.get(params, :scale) == :kwh
    assert Keyword.get(params, :value) == 1.25
  end
end
