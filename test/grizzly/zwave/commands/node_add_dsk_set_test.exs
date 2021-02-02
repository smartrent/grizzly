defmodule Grizzly.ZWave.Commands.NodeAddDSKSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeAddDSKSet

  test "creates the command and validates params" do
    params = [seq_number: 1, accept: true, input_dsk_length: 2, input_dsk: 46411]
    {:ok, _command} = NodeAddDSKSet.new(params)
  end

  describe "encodes params correctly" do
    test "encodes full bytes" do
      params = [seq_number: 1, accept: true, input_dsk_length: 2, input_dsk: 46411]
      {:ok, command} = NodeAddDSKSet.new(params)
      expected_binary = <<0x01, 0x01::size(1), 0x00::size(3), 0x02::size(4), 0xB5, 0x4B>>
      assert expected_binary == NodeAddDSKSet.encode_params(command)
    end

    test "encodes padded byte" do
      params = [seq_number: 1, accept: true, input_dsk_length: 2, input_dsk: 159]
      {:ok, command} = NodeAddDSKSet.new(params)
      expected_binary = <<0x01, 0x01::size(1), 0x00::size(3), 0x02::size(4), 0x00, 0x9F>>
      assert expected_binary == NodeAddDSKSet.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "decodes full bytes" do
      binary_params = <<0x01, 0x01::size(1), 0x00::size(3), 0x02::size(4), 0xB5, 0x4B>>
      {:ok, params} = NodeAddDSKSet.decode_params(binary_params)
      assert Keyword.get(params, :seq_number) == 1
      assert Keyword.get(params, :accept) == true
      assert Keyword.get(params, :input_dsk_length) == 2
      assert Keyword.get(params, :input_dsk) == 46411
    end

    test "decodes padded bytes" do
      binary_params = <<0x01, 0x01::size(1), 0x00::size(3), 0x02::size(4), 0x00, 0x9F>>
      {:ok, params} = NodeAddDSKSet.decode_params(binary_params)
      assert Keyword.get(params, :seq_number) == 1
      assert Keyword.get(params, :accept) == true
      assert Keyword.get(params, :input_dsk_length) == 2
      assert Keyword.get(params, :input_dsk) == 159
    end
  end
end
