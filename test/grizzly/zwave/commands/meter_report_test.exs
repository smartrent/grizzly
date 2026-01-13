defmodule Grizzly.ZWave.Commands.MeterReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MeterReport

  test "creates the command and validates params" do
    params = [meter_type: :electric, scale: :kwh, value: 1.25]
    {:ok, _command} = Commands.create(:meter_report, params)
  end

  test "encodes v1 params correctly" do
    params = [meter_type: :electric, scale: :kwh, value: 1.25]
    {:ok, command} = Commands.create(:meter_report, params)
    expected_binary = <<0x01, 0x02::3, 0x00::2, 0x01::3, 0x7D>>
    assert expected_binary == MeterReport.encode_params(nil, command)
  end

  test "encodes v5 params correctly" do
    params = [
      meter_type: :electric,
      scale: :pulse_count,
      value: 1.25,
      rate_type: :export,
      delta_time: 1,
      previous_value: 1.15
    ]

    {:ok, command} = Commands.create(:meter_report, params)
    expected_binary = <<0::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 0, 1, 115, 0>>
    assert expected_binary == MeterReport.encode_params(nil, command)

    params = [
      meter_type: :electric,
      scale: :pulse_count,
      value: 1.25,
      rate_type: :export
    ]

    {:ok, command} = Commands.create(:meter_report, params)
    expected_binary = <<0::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 0, 0, 0>>
    assert expected_binary == MeterReport.encode_params(nil, command)

    params = [
      meter_type: :electric,
      rate_type: :export,
      value: 1.25,
      delta_time: 1,
      previous_value: 1.15,
      scale: :kvarh
    ]

    {:ok, command} = Commands.create(:meter_report, params)
    expected_binary = <<1::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 0, 1, 115, 1>>
    assert expected_binary == MeterReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    # v1
    binary_params = <<0x01, 0x02::3, 0x00::2, 0x01::3, 0x7D>>
    {:ok, params} = MeterReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :meter_type) == :electric
    assert Keyword.get(params, :scale) == :kwh
    assert Keyword.get(params, :value) == 1.25

    # v2-v3
    # res::1, rate_type::2, meter_type::5, precision::3, scale::2, size::3, value::8, delta_time::16, previous_value::8
    binary_params = <<0::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 0, 1, 115>>
    {:ok, params} = MeterReport.decode_params(nil, binary_params)
    assert params[:meter_type] == :electric
    assert params[:rate_type] == :export
    assert params[:value] == 1.25
    assert params[:delta_time] == 1
    assert params[:previous_value] == 1.15
    assert params[:scale] == :pulse_count

    # v4-v5
    binary_params = <<1::1, 2::2, 1::5, 2::3, 3::2, 1::3, 0x7D, 0, 1, 115, 1>>
    {:ok, params} = MeterReport.decode_params(nil, binary_params)
    assert params[:meter_type] == :electric
    assert params[:rate_type] == :export
    assert params[:value] == 1.25
    assert params[:delta_time] == 1
    assert params[:previous_value] == 1.15
    assert params[:scale] == :kvarh
  end

  test "decodes params from real devices" do
    {:ok, params} = MeterReport.decode_params(nil, <<161, 74, 0, 0, 1, 45, 0, 0>>)
    assert params[:meter_type] == :electric
    assert params[:scale] == :a
    assert params[:rate_type] == :import
    assert params[:delta_time] == 301
    assert params[:value] == 0
    assert params[:previous_value] == 0

    {:ok, params} =
      MeterReport.decode_params(nil, <<161, 66, 93, 122, 1, 45, 93, 149>>)

    assert params[:meter_type] == :electric
    assert params[:scale] == :v
    assert params[:rate_type] == :import
    assert params[:delta_time] == 301
    assert params[:value] == 239.3
    assert params[:previous_value] == 239.57

    {:ok, params} =
      MeterReport.decode_params(nil, <<33, 84, 0, 0, 0, 0, 1, 45, 0, 0, 0, 0>>)

    assert params[:meter_type] == :electric
    assert params[:scale] == :w
    assert params[:rate_type] == :import
    assert params[:delta_time] == 301
    assert params[:value] == 0.0
    assert params[:previous_value] == 0.0

    {:ok, params} =
      MeterReport.decode_params(nil, <<33, 68, 0, 0, 0, 0, 1, 45, 0, 0, 0, 0>>)

    assert params[:meter_type] == :electric
    assert params[:scale] == :kwh
    assert params[:rate_type] == :import
    assert params[:delta_time] == 301
    assert params[:value] == 0.0
    assert params[:previous_value] == 0.0
  end
end
