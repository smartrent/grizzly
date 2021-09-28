defmodule Grizzly.ZWave.Commands.FailedNodeRemoveTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeRemove

  test "creates the command and validates params" do
    params = [seq_number: 2, node_id: 4]
    {:ok, _command} = FailedNodeRemove.new(params)
  end

  describe "encoding" do
    test "version 1-3 - only 8 bit node ids" do
      {:ok, command} = FailedNodeRemove.new(seq_number: 0x02, node_id: 0x04)

      for v <- 1..3 do
        assert FailedNodeRemove.encode_params(command, command_class_version: v) == <<0x02, 0x04>>
      end
    end

    test "version 4 - with 8 bit node id" do
      {:ok, command} = FailedNodeRemove.new(seq_number: 0x01, node_id: 0x04)

      assert FailedNodeRemove.encode_params(command) == <<0x01, 0x04, 0x00, 0x00>>
    end

    test "version 4 - with 16 bit node id" do
      {:ok, command} = FailedNodeRemove.new(seq_number: 0x01, node_id: 0x0401)

      assert FailedNodeRemove.encode_params(command) == <<0x01, 0xFF, 0x04, 0x01>>
    end
  end

  describe "decodes params correctly" do
    test "version 1-3 - no 16 bit node id support" do
      expected_params = [seq_number: 0x01, node_id: 0x04]
      {:ok, params} = FailedNodeRemove.decode_params(<<0x01, 0x04>>)

      assert_params(expected_params, params)
    end

    test "version 4 - 8 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x04]
      {:ok, params} = FailedNodeRemove.decode_params(<<0x01, 0x04, 0x00, 0x00>>)

      assert_params(expected_params, params)
    end

    test "version 4 - 16 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x0411]
      {:ok, params} = FailedNodeRemove.decode_params(<<0x01, 0xFF, 0x04, 0x11>>)

      assert_params(expected_params, params)
    end
  end

  defp assert_params(expected_params, params) do
    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
