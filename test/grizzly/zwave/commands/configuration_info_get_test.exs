defmodule Grizzly.ZWave.Commands.ConfigurationInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationInfoGet

  test "creates the command and validates params" do
    params = [param_number: 2]
    {:ok, _command} = ConfigurationInfoGet.new(params)
  end

  test "encodes params correctly" do
    params = [param_number: 2]
    {:ok, command} = ConfigurationInfoGet.new(params)
    expected_params_binary = <<0x02::16>>
    assert expected_params_binary == ConfigurationInfoGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02::16>>
    {:ok, params} = ConfigurationInfoGet.decode_params(params_binary)
    assert Keyword.get(params, :param_number) == 2
  end
end
