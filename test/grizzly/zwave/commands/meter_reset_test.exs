defmodule Grizzly.ZWave.Commands.MeterResetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MeterReset

  test "creates v2 command" do
    params = []
    {:ok, _command} = MeterReset.new(params)
  end

  test "creates v6 command and validates params" do
    params = [meter_type: :electric, scale: :kwh, value: 1.25, rate_type: :import]
    {:ok, _command} = MeterReset.new(params)
  end

  test "encodes v2 params correctly" do
    params = []
    {:ok, command} = MeterReset.new(params)
    expected_binary = <<>>
    assert expected_binary == MeterReset.encode_params(command)
  end

  test "encodes v6 params correctly" do
    params = [
      meter_type: :electric,
      scale: :w,
      value: 1.25,
      rate_type: :export
    ]

    {:ok, command} = MeterReset.new(params)
    expected_binary = <<0::1, 2::2, 1::5, 2::3, 2::2, 1::3, 0x7D, 0>>
    assert expected_binary == MeterReset.encode_params(command)

    params = [
      meter_type: :electric,
      scale: :kvarh,
      value: 1.25,
      rate_type: :export
    ]

    {:ok, command} = MeterReset.new(params)
    expected_binary = <<1::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 1>>
    assert expected_binary == MeterReset.encode_params(command)
  end

  test "decodes v2 params correctly" do
    binary_params = <<>>
    {:ok, params} = MeterReset.decode_params(binary_params)
    assert params == []
  end

  test "decodes v6 params correctly" do
    binary_params = <<0::1, 2::2, 1::5, 2::3, 2::2, 1::3, 0x7D, 0>>
    {:ok, params} = MeterReset.decode_params(binary_params)
    assert params[:meter_type] == :electric
    assert params[:scale] == :w
    assert params[:rate_type] == :export
    assert params[:value] == 1.25

    binary_params = <<1::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 1>>
    {:ok, params} = MeterReset.decode_params(binary_params)
    assert params[:meter_type] == :electric
    assert params[:scale] == :kvarh
    assert params[:rate_type] == :export
    assert params[:value] == 1.25
  end
end
