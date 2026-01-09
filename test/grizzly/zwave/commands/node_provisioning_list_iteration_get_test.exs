defmodule Grizzly.ZWave.Commands.NodeProvisioningListIterationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NodeProvisioningListIterationGet

  test "creates the command and validates params" do
    params = [seq_number: 0x01, remaining_counter: 2]
    {:ok, _command} = Commands.create(:node_provisioning_list_iteration_get, params)
  end

  test "encodes params correctly" do
    params = [seq_number: 0x01, remaining_counter: 2]
    {:ok, command} = Commands.create(:node_provisioning_list_iteration_get, params)
    expected_binary = <<0x01, 0x02>>
    assert expected_binary == NodeProvisioningListIterationGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x02>>
    {:ok, params} = NodeProvisioningListIterationGet.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 1
    assert Keyword.get(params, :remaining_counter) == 2
  end
end
