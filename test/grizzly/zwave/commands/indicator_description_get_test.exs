defmodule Grizzly.ZWave.Commands.IndicatorDescriptionGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.IndicatorDescriptionGet

  test "creates the command and validates params" do
    params = [indicator_id: :armed]
    {:ok, _command} = Commands.create(:indicator_description_get, params)
  end

  test "encodes params correctly" do
    params = [indicator_id: :armed]
    {:ok, command} = Commands.create(:indicator_description_get, params)
    expected_params_binary = <<0x01>>
    assert expected_params_binary == IndicatorDescriptionGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02>>
    {:ok, params} = IndicatorDescriptionGet.decode_params(nil, params_binary)
    assert Keyword.get(params, :indicator_id) == :disarmed
  end
end
