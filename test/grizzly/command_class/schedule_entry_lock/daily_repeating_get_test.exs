defmodule Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingGet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %DailyRepeatingGet{}} = DailyRepeatingGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1, seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x4E, 0x0E, 0x02, 0x01>>

      assert {:ok, binary} == DailyRepeatingGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1024, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :slot_id, 1024, DailyRepeatingGet})

      assert {:error, error} == DailyRepeatingGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %DailyRepeatingGet{}} =
               DailyRepeatingGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} =
        DailyRepeatingGet.init(user_id: 2, slot_id: 1, seq_number: 0x10, retries: 0)

      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               DailyRepeatingGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = DailyRepeatingGet.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :schedule_entry_lock,
        command: :daily_repeating_report,
        value: %{
          user_id: 1,
          slot_id: 2,
          action: :enabled,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0
        }
      }

      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1)
      packet = Packet.new(body: report)

      assert {
               :done,
               {
                 :ok,
                 %{
                   user_id: 1,
                   slot_id: 2,
                   action: :enabled,
                   weekdays: [:monday, :friday],
                   start_hour: 9,
                   start_minute: 0,
                   duration_hour: 1,
                   duration_minute: 0
                 }
               }
             } == DailyRepeatingGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = DailyRepeatingGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = DailyRepeatingGet.init(user_id: 2, slot_id: 1)

      assert {:continue, %DailyRepeatingGet{user_id: 2, slot_id: 1}} ==
               DailyRepeatingGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
