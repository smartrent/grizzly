defmodule Grizzly.ZWave.Commands.S2ResynchronizationEventTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.S2ResynchronizationEvent

  test "creates the command and validates params" do
    params = [node_id: 5, reason: 0]
    {:ok, _command} = S2ResynchronizationEvent.new(params)
  end

  test "encodes params correctly" do
    params = [node_id: 5, reason: 0]
    {:ok, command} = S2ResynchronizationEvent.new(params)
    expected_binary = <<5, 0>>
    assert expected_binary == S2ResynchronizationEvent.encode_params(command)
  end

  test "decodes  params correctly" do
    binary_params = <<5, 0>>
    {:ok, params} = S2ResynchronizationEvent.decode_params(binary_params)
    assert Keyword.get(params, :node_id) == 5
    assert Keyword.get(params, :reason) == 0
  end
end
