defmodule Grizzly.ZWave.Commands.AssociationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationSet

  test "creates the command and validates params" do
    params = [grouping_identifier: 2, nodes: [4, 5, 6]]
    {:ok, _command} = AssociationSet.new(params)
  end

  test "encodes params correctly" do
    params = [grouping_identifier: 2, nodes: [4, 5, 6]]
    {:ok, command} = AssociationSet.new(params)
    expected_binary = <<0x02, 0x04, 0x05, 0x06>>
    assert expected_binary == AssociationSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x04, 0x05, 0x06>>
    {:ok, params} = AssociationSet.decode_params(binary_params)
    assert Keyword.get(params, :grouping_identifier) == 2
    assert Enum.sort(Keyword.get(params, :nodes)) == [4, 5, 6]
  end
end
