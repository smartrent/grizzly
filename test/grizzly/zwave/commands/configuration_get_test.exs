defmodule Grizzly.ZWave.Commands.ConfigurationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ConfigurationGet

  test "creates the command and validates params" do
    params = [param_number: 2]
    {:ok, _command} = Commands.create(:configuration_get, params)
  end

  test "encodes params correctly" do
    params = [param_number: 2]
    {:ok, command} = Commands.create(:configuration_get, params)
    expected_params_binary = <<0x02>>
    assert expected_params_binary == ConfigurationGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02>>
    {:ok, params} = ConfigurationGet.decode_params(params_binary)
    assert Keyword.get(params, :param_number) == 2
  end
end
