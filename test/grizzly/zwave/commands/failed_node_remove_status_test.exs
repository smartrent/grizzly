defmodule Grizzly.ZWave.Commands.FailedNodeRemoveStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeRemoveStatus

  test "creates the command and validates params" do
    params = [seq_number: 2, node_id: 4, status: :done]
    {:ok, _command} = FailedNodeRemoveStatus.new(params)
  end

  test "encodes params correctly" do
    params = [seq_number: 2, node_id: 4, status: :done]
    {:ok, command} = FailedNodeRemoveStatus.new(params)
    expected_binary = <<0x02, 0x01, 0x04>>
    assert expected_binary == FailedNodeRemoveStatus.encode_params(command)
  end

  describe "decodes params correctly" do
    test "NetworkWorkManagementInclusion < v3" do
      params_binary = <<0x02, 0x00, 0x04>>
      {:ok, params} = FailedNodeRemoveStatus.decode_params(params_binary)
      assert Keyword.get(params, :seq_number) == 2
      assert Keyword.get(params, :node_id) == 4
      assert Keyword.get(params, :status) == :failed_node_not_found
    end

    test "NetworkWorkManagementInclusion < v4 (long range)" do
      params_binary = <<0x02, 0x00, 0x01, 0x00>>
      {:ok, params} = FailedNodeRemoveStatus.decode_params(params_binary)
      assert Keyword.get(params, :seq_number) == 2
      assert Keyword.get(params, :node_id) == 256
      assert Keyword.get(params, :status) == :failed_node_not_found
    end
  end
end
