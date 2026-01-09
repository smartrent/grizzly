defmodule Grizzly.ZWave.Commands.FailedNodeListGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.FailedNodeListGet

  test "creates the command and validates params" do
    params = [seq_number: 0x01]
    {:ok, _command} = Commands.create(:failed_node_list_get, params)
  end

  test "encodes params correctly" do
    params = [seq_number: 0x01]
    {:ok, command} = Commands.create(:failed_node_list_get, params)
    expected_binary = <<0x01>>

    assert expected_binary == FailedNodeListGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = FailedNodeListGet.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 0x02
  end
end
