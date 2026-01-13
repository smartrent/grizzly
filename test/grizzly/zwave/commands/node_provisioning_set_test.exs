defmodule Grizzly.ZWave.Commands.NodeProvisioningSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NodeProvisioningSet
  alias Grizzly.ZWave.DSK
  alias GrizzlyTest.Utils

  test "creates the command and validates params" do
    params = [
      seq_number: 0x01,
      dsk: Utils.mkdsk(),
      meta_extensions: []
    ]

    {:ok, _command} = Commands.create(:node_provisioning_set, params)
  end

  test "encodes params correctly" do
    params = [
      seq_number: 0x01,
      dsk: Utils.mkdsk(),
      meta_extensions: []
    ]

    {:ok, command} = Commands.create(:node_provisioning_set, params)

    expected_binary =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    assert expected_binary == NodeProvisioningSet.encode_params(nil, command)

    params = [
      seq_number: 0x01,
      dsk: DSK.to_string(Utils.mkdsk()),
      meta_extensions: []
    ]

    assert {:ok, params} ==
             NodeProvisioningSet.decode_params(
               nil,
               NodeProvisioningSet.encode_params(nil, command)
             )
  end

  test "decodes params correctly" do
    binary_params =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    {:ok, params} = NodeProvisioningSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :seq_number) == 1
    assert Keyword.get(params, :dsk) == DSK.to_string(Utils.mkdsk())
    assert Keyword.get(params, :meta_extensions) == []
  end
end
