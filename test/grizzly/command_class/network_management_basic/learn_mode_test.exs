defmodule Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, _} = LearnModeSet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = LearnModeSet.init(mode: :enable, seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x4D, 0x01, 10, 0, 1>>

      assert {:ok, binary} == LearnModeSet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = LearnModeSet.init(mode: :blue, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :mode, :blue,
           Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet}
        )

      assert {:error, error} == LearnModeSet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = LearnModeSet.init(seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:ack_response])

      assert {:continue, ^command} = LearnModeSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = LearnModeSet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == LearnModeSet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = LearnModeSet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %LearnModeSet{retries: 1}} = LearnModeSet.handle_response(command, packet)
    end

    test "handles default set complete response" do
      report = %{command: :learn_mode_set_status, report: %{status: :done, new_node_id: 1}}
      packet = Packet.new(body: report)
      {:ok, command} = LearnModeSet.init(seq_number: 0x01)

      assert {:done, {:ok, %{status: :done, new_node_id: 1}}} ==
               LearnModeSet.handle_response(command, packet)
    end
  end
end
