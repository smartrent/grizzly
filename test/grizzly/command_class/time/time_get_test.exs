defmodule Grizzly.CommandClass.Time.TimeGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Time.TimeGet

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %TimeGet{}} == TimeGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = TimeGet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x8A, 0x01>>

      assert {:ok, binary} == TimeGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = TimeGet.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = TimeGet.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = TimeGet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == TimeGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = TimeGet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %TimeGet{}} = TimeGet.handle_response(command, packet)
    end

    test "handles time report responses" do
      report = %{
        command_class: :time,
        command: :time_report,
        value: %{hour: 1, minute: 2, second: 3}
      }

      packet = Packet.new(body: report)
      {:ok, command} = TimeGet.init([])

      assert {:done, {:ok, %{hour: 1, minute: 2, second: 3}}} ==
               TimeGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = TimeGet.init([])
      assert {:continue, %TimeGet{}} = TimeGet.handle_response(command, %{command_class: :foo})
    end
  end
end
