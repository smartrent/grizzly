defmodule Grizzly.ZWave.Commands.PriorityRouteGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PriorityRouteGet

  test "creates the command and validates params" do
    params = [node_id: 4]
    {:ok, _command} = PriorityRouteGet.new(params)
  end

  test "encodes params correctly" do
    params = [node_id: 4]
    {:ok, command} = PriorityRouteGet.new(params)
    expected_binary = <<0x04>>
    assert expected_binary == PriorityRouteGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x04>>
    {:ok, params} = PriorityRouteGet.decode_params(binary_params)
    assert Keyword.get(params, :node_id) == 4
  end
end
