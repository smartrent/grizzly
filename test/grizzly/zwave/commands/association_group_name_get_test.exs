defmodule Grizzly.ZWave.Commands.AssociationGroupNameGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupNameGet

  test "creates the command and validates params" do
    params = [group_id: 2]
    {:ok, _command} = Commands.create(:association_group_name_get, params)
  end

  test "encodes params correctly" do
    params = [group_id: 2]
    {:ok, command} = Commands.create(:association_group_name_get, params)
    expected_binary = <<0x02>>
    assert expected_binary == AssociationGroupNameGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = AssociationGroupNameGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :group_id) == 2
  end
end
