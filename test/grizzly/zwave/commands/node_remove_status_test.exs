defmodule Grizzly.ZWave.Commands.NodeRemoveStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeRemoveStatus

  test "correct command byte" do
    {:ok, cmd} = NodeRemoveStatus.new()
    assert cmd.command_byte == 0x04
  end

  test "correct name" do
    {:ok, cmd} = NodeRemoveStatus.new()
    assert cmd.name == :node_remove_status
  end

  describe "encoding" do
    test "version 1-3" do
      expected_binary = <<0x01, 0x06, 0x05>>

      for v <- [1, 2, 3] do
        {:ok, cmd} =
          NodeRemoveStatus.new(
            seq_number: 0x01,
            node_id: 0x05,
            status: :done
          )

        assert NodeRemoveStatus.encode_params(cmd, command_class_version: v) == expected_binary
      end
    end

    test "version 4 - with 8 bit node id" do
      {:ok, cmd} = NodeRemoveStatus.new(seq_number: 0x01, node_id: 0x05, status: :done)

      expected_binary = <<0x01, 0x06, 0x05, 0x05::16>>

      assert NodeRemoveStatus.encode_params(cmd) == expected_binary
    end

    test "version 4 - with 16 bit node id" do
      {:ok, cmd} = NodeRemoveStatus.new(seq_number: 0x01, node_id: 0x1010, status: :done)

      expected_binary = <<0x01, 0x06, 0xFF, 0x10, 0x10>>

      assert NodeRemoveStatus.encode_params(cmd) == expected_binary
    end
  end

  describe "parsing" do
    test "version 1-3" do
      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x05
      ]

      {:ok, result} = NodeRemoveStatus.decode_params(<<0x01, 0x06, 0x05>>)

      assert_params(expected_params, result)
    end

    test "version 4 - with 8 bit node id" do
      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x05
      ]

      {:ok, result} = NodeRemoveStatus.decode_params(<<0x01, 0x06, 0x05, 0x00, 0x00>>)

      assert_params(expected_params, result)
    end

    test "version 4 - with 16 bit node id" do
      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x10A1
      ]

      {:ok, result} = NodeRemoveStatus.decode_params(<<0x01, 0x06, 0xFF, 0x10, 0xA1>>)

      assert_params(expected_params, result)
    end
  end

  defp assert_params(expected_params, params) do
    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
