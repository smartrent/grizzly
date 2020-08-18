defmodule Grizzly.ZWave.Commands.IndicatorDescriptionReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.IndicatorDescriptionReport

  test "creates the command and validates params" do
    params = [indicator_id: :armed, description: "Alarm will sound"]
    {:ok, _command} = IndicatorDescriptionReport.new(params)
  end

  test "encodes params correctly" do
    description = "Alarm will sound"
    params = [indicator_id: :armed, description: description]
    {:ok, command} = IndicatorDescriptionReport.new(params)
    size = byte_size(description)
    expected_params_binary = <<0x01, size>> <> description
    assert expected_params_binary == IndicatorDescriptionReport.encode_params(command)
  end

  test "decodes params correctly" do
    description = "Alarm will sound"
    size = byte_size(description)
    params_binary = <<0x01, size>> <> description
    {:ok, params} = IndicatorDescriptionReport.decode_params(params_binary)
    assert Keyword.get(params, :indicator_id) == :armed
    assert Keyword.get(params, :description) == description
  end
end
