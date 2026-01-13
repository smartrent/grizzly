defmodule Grizzly.ZWave.Commands.AssociationGroupInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupInfoGet

  test "creates the command and validates params" do
    params = [all: false, group_id: 2]
    {:ok, _command} = Commands.create(:association_group_info_get, params)
    params = [all: true, refresh_cache: true]
    {:ok, _command} = Commands.create(:association_group_info_get, params)
  end

  test "encodes params correctly - all" do
    params = [all: true, refresh_cache: true]
    {:ok, command} = Commands.create(:association_group_info_get, params)
    expected_binary = <<0x01::1, 0x01::1, 0x00::6, 0x00>>
    assert expected_binary == AssociationGroupInfoGet.encode_params(nil, command)
  end

  test "encodes params correctly - one" do
    params = [refresh_cache: false, all: false, group_id: 2]
    {:ok, command} = Commands.create(:association_group_info_get, params)
    expected_binary = <<0x00::1, 0x00::1, 0x00::6, 0x02>>
    assert expected_binary == AssociationGroupInfoGet.encode_params(nil, command)
  end

  test "decodes params correctly - all" do
    binary_params = <<0x01::1, 0x01::1, 0x00::6, 0x00>>
    {:ok, params} = AssociationGroupInfoGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :all) == true
    assert Keyword.get(params, :refresh_cache) == true
    assert Keyword.get(params, :group_id) == 0
  end

  test "decodes params correctly - one" do
    binary_params = <<0x00::1, 0x00::1, 0x00::6, 0x02>>
    {:ok, params} = AssociationGroupInfoGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :all) == false
    assert Keyword.get(params, :refresh_cache) == false
    assert Keyword.get(params, :group_id) == 2
  end
end
