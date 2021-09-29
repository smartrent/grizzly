defmodule Grizzly.ZWave.Commands.FailedNodeRemoveStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeRemoveStatus

  test "creates the command and validates params" do
    params = [seq_number: 2, node_id: 4, status: :done]
    {:ok, _command} = FailedNodeRemoveStatus.new(params)
  end

  describe "encoding" do
    test "version 1-3 - only 8 bit node id" do
      expected_bin = <<0x01, 0x01, 0x04>>
      {:ok, command} = FailedNodeRemoveStatus.new(seq_number: 0x01, status: :done, node_id: 0x04)

      assert FailedNodeRemoveStatus.encode_params(command, command_class_version: 3) ==
               expected_bin
    end

    test "version 4 - with 8 bit node ids" do
      expected_bin = <<0x01, 0x01, 0x04, 0x04::16>>
      {:ok, command} = FailedNodeRemoveStatus.new(seq_number: 0x01, status: :done, node_id: 0x04)

      assert FailedNodeRemoveStatus.encode_params(command) ==
               expected_bin
    end

    test "version 4 - with 16 bit node ids" do
      expected_bin = <<0x01, 0x01, 0xFF, 0x15, 0xAC>>

      {:ok, command} =
        FailedNodeRemoveStatus.new(seq_number: 0x01, status: :done, node_id: 0x15AC)

      assert FailedNodeRemoveStatus.encode_params(command) ==
               expected_bin
    end
  end

  describe "decoding" do
    test "version 1-3 - only 8 bit node id" do
      expected_params = [seq_number: 0x02, node_id: 0x04, status: :failed_node_not_found]
      {:ok, params} = FailedNodeRemoveStatus.decode_params(<<0x02, 0x00, 0x04>>)

      assert_params(expected_params, params)
    end

    test "version 4 - with 8 bit node ids" do
      expected_params = [seq_number: 0x02, node_id: 0x04, status: :failed_node_not_found]
      {:ok, params} = FailedNodeRemoveStatus.decode_params(<<0x02, 0x00, 0x04, 0x00, 0x00>>)

      assert_params(expected_params, params)
    end

    test "version 4 - with 16 bit node ids" do
      expected_params = [seq_number: 0x02, node_id: 0x043B, status: :failed_node_not_found]
      {:ok, params} = FailedNodeRemoveStatus.decode_params(<<0x02, 0x00, 0xFF, 0x04, 0x3B>>)

      assert_params(expected_params, params)
    end
  end

  defp assert_params(expected_params, params) do
    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
