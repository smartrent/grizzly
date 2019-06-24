defmodule Grizzly.CommandClass.Time.DateGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Time.DateGet

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %DateGet{}} == DateGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = DateGet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x8A, 0x03>>

      assert {:ok, binary} == DateGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = DateGet.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = DateGet.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = DateGet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == DateGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = DateGet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %DateGet{}} = DateGet.handle_response(command, packet)
    end

    test "handles time report responses" do
      report = %{
        command_class: :time,
        command: :date_report,
        value: %{year: 2019, month: 12, day: 25}
      }

      packet = Packet.new(body: report)
      {:ok, command} = DateGet.init([])

      assert {:done, {:ok, %{year: 2019, month: 12, day: 25}}} ==
               DateGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = DateGet.init([])
      assert {:continue, %DateGet{}} = DateGet.handle_response(command, %{command_class: :foo})
    end
  end
end
