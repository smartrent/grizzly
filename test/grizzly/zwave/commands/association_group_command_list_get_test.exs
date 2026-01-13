defmodule Grizzly.ZWave.Commands.AssociationGroupCommandListGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupCommandListGet

  test "creates the command and validates params" do
    params = [allow_cache: false, group_id: 2]
    {:ok, _command} = Commands.create(:association_group_command_list_get, params)
  end

  test "encodes params correctly " do
    params = [allow_cache: false, group_id: 2]
    {:ok, command} = Commands.create(:association_group_command_list_get, params)
    expected_binary = <<0x00::1, 0x00::7, 0x02>>
    assert expected_binary == AssociationGroupCommandListGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::1, 0x00::7, 0x02>>
    {:ok, params} = AssociationGroupCommandListGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :allow_cache) == false
    assert Keyword.get(params, :group_id) == 2
  end
end
