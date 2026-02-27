defmodule Grizzly.ZWave.Commands.AssociationRemoveTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "creates the command and validates params" do
    params = [grouping_identifier: 2, nodes: [4, 5, 6]]
    {:ok, _command} = Commands.create(:association_remove, params)
  end

  test "encodes params correctly" do
    params = [grouping_identifier: 2, nodes: [4, 5, 6]]
    {:ok, command} = Commands.create(:association_remove, params)
    expected_binary = <<0x85, 0x04, 0x02, 0x04, 0x05, 0x06>>
    assert expected_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x85, 0x04, 0x02, 0x04, 0x05, 0x06>>
    {:ok, cmd} = Grizzly.decode_command(binary_params)
    assert Keyword.get(cmd.params, :grouping_identifier) == 2
    assert Enum.sort(Keyword.get(cmd.params, :nodes)) == [4, 5, 6]
  end
end
