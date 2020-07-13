defmodule Grizzly.ZWave.Commands.LearnModeSetStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.LearnModeSetStatus

  describe "creates the command and validates params" do
    test "v1" do
      params = [
        seq_number: 3,
        status: :done,
        new_node_id: 10
      ]

      {:ok, _command} = LearnModeSetStatus.new(params)
    end

    test "v2" do
      params = [
        seq_number: 3,
        status: :done,
        new_node_id: 10,
        granted_keys: [:s2_authenticated],
        kex_fail_type: :none,
        dsk: "00000-11111-22222-33333-44444-55555-66666-77777"
      ]

      {:ok, _command} = LearnModeSetStatus.new(params)
    end
  end

  describe "encodes params correctly" do
    test "v1" do
      params = [
        seq_number: 3,
        status: :done,
        new_node_id: 10
      ]

      {:ok, command} = LearnModeSetStatus.new(params)
      expected_binary = <<0x03, 0x06, 0x00, 0x0A>>
      assert expected_binary == LearnModeSetStatus.encode_params(command)
    end

    test "v2" do
      params = [
        seq_number: 3,
        status: :done,
        new_node_id: 10,
        granted_keys: [:s2_authenticated],
        kex_fail_type: :none,
        dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
      ]

      {:ok, command} = LearnModeSetStatus.new(params)

      expected_binary =
        <<0x03, 0x06, 0x00, 0x0A, 0x02, 0x00>> <>
          <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

      assert expected_binary == LearnModeSetStatus.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1" do
      params_binary = <<0x03, 0x06, 0x00, 0x0A>>
      {:ok, params} = LearnModeSetStatus.decode_params(params_binary)
      assert Keyword.get(params, :seq_number) == 3
      assert Keyword.get(params, :status) == :done
      assert Keyword.get(params, :new_node_id) == 10
    end

    test "v2" do
      params_binary =
        <<0x03, 0x06, 0x00, 0x0A, 0x02, 0x00>> <>
          <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

      {:ok, params} = LearnModeSetStatus.decode_params(params_binary)
      assert Keyword.get(params, :seq_number) == 3
      assert Keyword.get(params, :status) == :done
      assert Keyword.get(params, :new_node_id) == 10
      assert Keyword.get(params, :granted_keys) == [:s2_authenticated]
      assert Keyword.get(params, :dsk) == "50285-18819-09924-30691-15973-33711-04005-03623"
    end
  end
end
