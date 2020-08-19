defmodule Grizzly.ZWave.Commands.IndicatorDescriptionGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.IndicatorDescriptionGet

  test "creates the command and validates params" do
    params = [indicator_id: :armed]
    {:ok, _command} = IndicatorDescriptionGet.new(params)
  end

  test "encodes params correctly" do
    params = [indicator_id: :armed]
    {:ok, command} = IndicatorDescriptionGet.new(params)
    expected_params_binary = <<0x01>>
    assert expected_params_binary == IndicatorDescriptionGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02>>
    {:ok, params} = IndicatorDescriptionGet.decode_params(params_binary)
    assert Keyword.get(params, :indicator_id) == :disarmed
  end
end
