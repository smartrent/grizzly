defmodule Grizzly.ZWave.Commands.DSKGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.DSKGet

  test "creates the command and validates params (using defaults)" do
    params = [seq_number: 0x01]
    {:ok, command} = DSKGet.new(params)

    assert :learn == Command.param!(command, :add_mode)
  end

  test "creates the command and validates params (overriding defaults)" do
    params = [seq_number: 0x01, add_mode: :add]
    {:ok, command} = DSKGet.new(params)

    assert :add == Command.param!(command, :add_mode)
  end

  describe "encodes params correctly" do
    test "when add mode is learn mode" do
      params = [seq_number: 0x01]
      {:ok, command} = DSKGet.new(params)
      expected_binary = <<0x01, 0x00>>

      assert expected_binary == DSKGet.encode_params(command)
    end

    test "when add mode is add mode" do
      params = [seq_number: 0x01, add_mode: :add]
      {:ok, command} = DSKGet.new(params)
      expected_binary = <<0x01, 0x01>>

      assert expected_binary == DSKGet.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "gets the sequence number correctly" do
      binary_params = <<0x02, 0x00>>
      {:ok, params} = DSKGet.decode_params(binary_params)
      assert Keyword.get(params, :seq_number) == 0x02
    end

    test "when add mode is learn mode" do
      binary_params = <<0x02, 0x00>>
      {:ok, params} = DSKGet.decode_params(binary_params)
      assert Keyword.get(params, :add_mode) == :learn
    end

    test "when add mode is add mode" do
      binary_params = <<0x02, 0x01>>
      {:ok, params} = DSKGet.decode_params(binary_params)
      assert Keyword.get(params, :add_mode) == :add
    end
  end
end
