defmodule Grizzly.CommandClass.ScheduleEntryLock.YearDayGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock.YearDayGet
  alias Grizzly.CommandClass.ScheduleEntryLock

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %YearDayGet{}} = YearDayGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1, seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x4E, 0x07, 0x02, 0x01>>

      assert {:ok, binary} == YearDayGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %YearDayGet{}} = YearDayGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1, seq_number: 0x10, retries: 0)

      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               YearDayGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = YearDayGet.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :schedule_entry_lock,
        command: :year_day_report,
        value: %{
          user_id: 2,
          slot_id: 1,
          start_year: ScheduleEntryLock.decode_year(19),
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: ScheduleEntryLock.decode_year(19),
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46
        }
      }

      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1)
      packet = Packet.new(body: report)

      assert {
               :done,
               {
                 :ok,
                 %{
                   user_id: 2,
                   slot_id: 1,
                   start_year: 2019,
                   start_month: 7,
                   start_day: 10,
                   start_hour: 13,
                   start_minute: 45,
                   stop_year: 2019,
                   stop_month: 8,
                   stop_day: 11,
                   stop_hour: 14,
                   stop_minute: 46
                 }
               }
             } == YearDayGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = YearDayGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = YearDayGet.init(user_id: 2, slot_id: 1)

      assert {:continue, %YearDayGet{user_id: 2, slot_id: 1}} ==
               YearDayGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
