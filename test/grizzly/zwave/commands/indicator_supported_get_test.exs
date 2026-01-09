defmodule Grizzly.ZWave.Commands.IndicatorSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.IndicatorSupportedGet

  test "creates the command and validates params" do
    params = [indicator_id: :armed]
    {:ok, _command} = Commands.create(:indicator_supported_get, params)
  end

  test "encodes params correctly" do
    params = [indicator_id: :armed]
    {:ok, command} = Commands.create(:indicator_supported_get, params)
    expected_params_binary = <<0x01>>
    assert expected_params_binary == IndicatorSupportedGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02>>
    {:ok, params} = IndicatorSupportedGet.decode_params(params_binary)
    assert Keyword.get(params, :indicator_id) == :disarmed
  end
end
