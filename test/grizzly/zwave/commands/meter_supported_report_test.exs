defmodule Grizzly.ZWave.Commands.MeterSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MeterSupportedReport

  test "creates the command and validates params" do
    params = [
      meter_reset_supported: true,
      meter_type: :electric,
      supported_scales: [:kwh, :kvah, :w, :kvar, :kvarh],
      rate_type: :import_export
    ]

    {:ok, _command} = Commands.create(:meter_supported_report, params)
  end

  test "encodes v2 params correctly" do
    params = [
      meter_reset_supported: true,
      meter_type: :electric,
      supported_scales: [:kwh, :kvah, :w]
    ]

    {:ok, command} = Commands.create(:meter_supported_report, params)
    expected_binary = <<1::1, 0::2, 1::5, 0::4, 7::4>>
    assert expected_binary == MeterSupportedReport.encode_params(command)
  end

  test "encodes v5 params correctly" do
    params = [
      meter_reset_supported: true,
      meter_type: :electric,
      supported_scales: [:kwh, :kvah, :w, :kvar, :kvarh],
      rate_type: :import_export
    ]

    {:ok, command} = Commands.create(:meter_supported_report, params)
    expected_binary = <<1::1, 3::2, 1::5, 1::1, 7::7, 1, 3>>
    assert expected_binary == MeterSupportedReport.encode_params(command)
  end

  test "decodes v2 params correctly" do
    binary_params = <<1::1, 0::2, 1::5, 0::4, 7::4>>
    {:ok, params} = MeterSupportedReport.decode_params(binary_params)
    assert Keyword.get(params, :meter_type) == :electric
    supported_scales = Keyword.get(params, :supported_scales)
    assert Enum.sort(supported_scales) == [:kvah, :kwh, :w]
    assert Keyword.get(params, :meter_reset_supported) == true
  end

  test "decodes v5 params correctly" do
    binary_params = <<1::1, 3::2, 1::5, 1::1, 7::7, 1, 3>>
    {:ok, params} = MeterSupportedReport.decode_params(binary_params)
    assert Keyword.get(params, :meter_type) == :electric
    supported_scales = Keyword.get(params, :supported_scales)
    assert Enum.sort(supported_scales) == [:kvah, :kvar, :kvarh, :kwh, :w]
    assert Keyword.get(params, :meter_reset_supported) == true
    assert Keyword.get(params, :rate_type) == :import_export
  end
end
