defmodule Grizzly.CommandClass.ScheduleEntryLock.SupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock.SupportedGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %SupportedGet{}} = SupportedGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = SupportedGet.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x4E, 0x09>>

      assert {:ok, binary} == SupportedGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = SupportedGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %SupportedGet{}} = SupportedGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = SupportedGet.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == SupportedGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = SupportedGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = SupportedGet.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :schedule_entry_lock,
        command: :supported_report,
        value: %{
          week_day_slots: 0,
          year_day_slots: 1,
          daily_repeating: 7
        }
      }

      {:ok, command} = SupportedGet.init([])
      packet = Packet.new(body: report)

      assert {
               :done,
               {
                 :ok,
                 %{
                   week_day_slots: 0,
                   year_day_slots: 1,
                   daily_repeating: 7
                 }
               }
             } == SupportedGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = SupportedGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = SupportedGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = SupportedGet.init([])

      assert {:continue, %SupportedGet{}} ==
               SupportedGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
