defmodule Grizzly.ZWave.Commands.FailedNodeReplaceStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeReplaceStatus

  test "encodes params correctly" do
    {:ok, command} =
      FailedNodeReplaceStatus.new(
        seq_number: 54,
        status: :security_failed,
        node_id: 5,
        granted_keys: [],
        kex_fail_type: :curves
      )

    expected_binary = <<0x36, 0x09, 0x05, 0x00, 0x03>>
    assert expected_binary == FailedNodeReplaceStatus.encode_params(command)

    {:ok, command} =
      FailedNodeReplaceStatus.new(
        seq_number: 10,
        status: :done,
        node_id: 3,
        granted_keys: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
        kex_fail_type: :none
      )

    expected_binary = <<0x0A, 0x06, 0x03, 0x07, 0x00>>
    assert expected_binary == FailedNodeReplaceStatus.encode_params(command)
  end

  test "decodes params correctly" do
    expected_params = [
      seq_number: 10,
      status: :done,
      node_id: 3,
      granted_keys: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
      kex_fail_type: :none
    ]

    assert {:ok, expected_params} ==
             FailedNodeReplaceStatus.decode_params(<<0x0A, 0x06, 0x03, 0x07, 0x00>>)

    expected_params = [
      seq_number: 10,
      status: :security_failed,
      node_id: 3,
      granted_keys: [],
      kex_fail_type: :auth
    ]

    assert {:ok, expected_params} ==
             FailedNodeReplaceStatus.decode_params(<<0x0A, 0x09, 0x03, 0x00, 0x07>>)
  end
end
