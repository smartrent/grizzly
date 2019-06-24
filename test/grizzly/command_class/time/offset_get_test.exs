defmodule Grizzly.CommandClass.Time.OffsetGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Time.OffsetGet

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %OffsetGet{}} == OffsetGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = OffsetGet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x8A, 0x06>>

      assert {:ok, binary} == OffsetGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = OffsetGet.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = OffsetGet.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = OffsetGet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == OffsetGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = OffsetGet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %OffsetGet{}} = OffsetGet.handle_response(command, packet)
    end

    test "handles time offset report responses" do
      report = %{
        command_class: :time,
        command: :time_offset_report,
        value: %{
          sign_tzo: 1,
          hour_tzo: 4,
          minute_tzo: 0,
          sign_offset_dst: 0,
          minute_offset_dst: 60,
          month_start_dst: 3,
          day_start_dst: 10,
          hour_start_dst: 2,
          month_end_dst: 11,
          day_end_dst: 3,
          hour_end_dst: 2
        }
      }

      packet = Packet.new(body: report)
      {:ok, command} = OffsetGet.init([])

      assert {:done,
              {:ok,
               %{
                 sign_tzo: 1,
                 hour_tzo: 4,
                 minute_tzo: 0,
                 sign_offset_dst: 0,
                 minute_offset_dst: 60,
                 month_start_dst: 3,
                 day_start_dst: 10,
                 hour_start_dst: 2,
                 month_end_dst: 11,
                 day_end_dst: 3,
                 hour_end_dst: 2
               }}} ==
               OffsetGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = OffsetGet.init([])

      assert {:continue, %OffsetGet{}} =
               OffsetGet.handle_response(command, %{command_class: :foo})
    end
  end
end
