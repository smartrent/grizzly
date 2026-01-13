defmodule Grizzly.ZWave.Commands.StatisticsGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.StatisticsGet

  test "creates the command and validates params" do
    params = [node_id: 4]
    {:ok, _command} = Commands.create(:statistics_get, params)
  end

  test "encodes params correctly" do
    params = [node_id: 4]
    {:ok, command} = Commands.create(:statistics_get, params)
    expected_binary = <<0x04>>
    assert expected_binary == StatisticsGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x04>>
    {:ok, params} = StatisticsGet.decode_params(nil, params_binary)
    assert Keyword.get(params, :node_id) == 4
  end
end
