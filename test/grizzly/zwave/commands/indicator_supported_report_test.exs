defmodule Grizzly.ZWave.Commands.IndicatorSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.IndicatorSupportedReport

  test "creates the command and validates params" do
    params = [
      indicator_id: :armed,
      next_indicator_id: :ready,
      property_ids: [:multilevel, :timeout_seconds, :sound_level]
    ]

    {:ok, _command} = Commands.create(:indicator_supported_report, params)
  end

  test "encodes params correctly" do
    params = [
      indicator_id: :armed,
      next_indicator_id: :ready,
      property_ids: [:multilevel, :timeout_seconds, :sound_level]
    ]

    {:ok, command} = Commands.create(:indicator_supported_report, params)
    expected_params_binary = <<0x01, 0x03, 0x02, 0x82, 0x02>>
    assert expected_params_binary == IndicatorSupportedReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x01, 0x03, 0x02, 0x82, 0x02>>
    {:ok, params} = IndicatorSupportedReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :indicator_id) == :armed
    assert Keyword.get(params, :next_indicator_id) == :ready

    assert Enum.sort(Keyword.get(params, :property_ids)) == [
             :multilevel,
             :sound_level,
             :timeout_seconds
           ]
  end
end
