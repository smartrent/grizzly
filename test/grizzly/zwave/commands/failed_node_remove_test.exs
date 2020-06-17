defmodule Grizzly.ZWave.Commands.FailedNodeRemoveTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeRemove

  test "creates the command and validates params" do
    params = [seq_number: 2, node_id: 4]
    {:ok, _command} = FailedNodeRemove.new(params)
  end

  test "encodes params correctly" do
    params = [seq_number: 2, node_id: 4]
    {:ok, command} = FailedNodeRemove.new(params)
    expected_binary = <<0x02, 0x04>>
    assert expected_binary == FailedNodeRemove.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02, 0x04>>
    {:ok, params} = FailedNodeRemove.decode_params(params_binary)
    assert Keyword.get(params, :seq_number) == 2
    assert Keyword.get(params, :node_id) == 4
  end
end
