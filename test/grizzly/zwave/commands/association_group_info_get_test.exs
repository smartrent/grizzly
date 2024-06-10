defmodule Grizzly.ZWave.Commands.AssociationGroupInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationGroupInfoGet

  test "creates the command and validates params" do
    params = [all: false, group_id: 2]
    {:ok, _command} = AssociationGroupInfoGet.new(params)
    params = [all: true, refresh_cache: true]
    {:ok, _command} = AssociationGroupInfoGet.new(params)
  end

  test "encodes params correctly - all" do
    params = [all: true, refresh_cache: true]
    {:ok, command} = AssociationGroupInfoGet.new(params)
    expected_binary = <<0x01::1, 0x01::1, 0x00::6, 0x00>>
    assert expected_binary == AssociationGroupInfoGet.encode_params(command)
  end

  test "encodes params correctly - one" do
    params = [refresh_cache: false, all: false, group_id: 2]
    {:ok, command} = AssociationGroupInfoGet.new(params)
    expected_binary = <<0x00::1, 0x00::1, 0x00::6, 0x02>>
    assert expected_binary == AssociationGroupInfoGet.encode_params(command)
  end

  test "decodes params correctly - all" do
    binary_params = <<0x01::1, 0x01::1, 0x00::6, 0x00>>
    {:ok, params} = AssociationGroupInfoGet.decode_params(binary_params)
    assert Keyword.get(params, :all) == true
    assert Keyword.get(params, :refresh_cache) == true
    assert Keyword.get(params, :group_id) == 0
  end

  test "decodes params correctly - one" do
    binary_params = <<0x00::1, 0x00::1, 0x00::6, 0x02>>
    {:ok, params} = AssociationGroupInfoGet.decode_params(binary_params)
    assert Keyword.get(params, :all) == false
    assert Keyword.get(params, :refresh_cache) == false
    assert Keyword.get(params, :group_id) == 2
  end
end
