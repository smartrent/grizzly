defmodule Grizzly.ZWave.Commands.ConfigurationPropertiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationPropertiesGet

  test "creates the command and validates params" do
    params = [param_number: 2]
    {:ok, _command} = ConfigurationPropertiesGet.new(params)
  end

  test "encodes params correctly" do
    params = [param_number: 2]
    {:ok, command} = ConfigurationPropertiesGet.new(params)
    expected_params_binary = <<0x02::size(16)>>
    assert expected_params_binary == ConfigurationPropertiesGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02::size(16)>>
    {:ok, params} = ConfigurationPropertiesGet.decode_params(params_binary)
    assert Keyword.get(params, :param_number) == 2
  end
end
