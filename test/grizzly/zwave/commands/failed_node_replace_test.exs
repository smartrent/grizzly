defmodule Grizzly.ZWave.Commands.FailedNodeReplaceTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeReplace

  test "encodes params correctly" do
    {:ok, command} =
      FailedNodeReplace.new(
        seq_number: 54,
        node_id: 5,
        mode: :start_failed_node_replace,
        tx_opt: :low_power
      )

    expected_binary = <<0x36, 0x05, 0x02, 0x01>>
    assert expected_binary == FailedNodeReplace.encode_params(command)

    {:ok, command} = FailedNodeReplace.new(seq_number: 54, node_id: 5)
    expected_binary = <<0x36, 0x05, 0x20, 0x07>>
    assert expected_binary == FailedNodeReplace.encode_params(command)
  end

  test "decodes params correctly" do
    expected_params = [
      mode: :start_failed_node_replace_s2,
      seq_number: 54,
      node_id: 5,
      tx_opt: :low_power
    ]

    assert {:ok, expected_params} == FailedNodeReplace.decode_params(<<0x36, 0x05, 0x02, 0x07>>)
  end
end
