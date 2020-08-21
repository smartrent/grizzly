defmodule Grizzly.ZWave.Commands.ConfigurationBulkGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationBulkGet

  test "creates the command and validates params" do
    params = [number_of_parameters: 2, offset: 3]
    {:ok, _command} = ConfigurationBulkGet.new(params)
  end

  test "encodes params correctly" do
    params = [number_of_parameters: 2, offset: 3]
    {:ok, command} = ConfigurationBulkGet.new(params)
    expected_params_binary = <<0x03::size(16), 0x02>>
    assert expected_params_binary == ConfigurationBulkGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x03::size(16), 0x02>>
    {:ok, params} = ConfigurationBulkGet.decode_params(params_binary)
    assert Keyword.get(params, :number_of_parameters) == 2
    assert Keyword.get(params, :offset) == 3
  end
end
