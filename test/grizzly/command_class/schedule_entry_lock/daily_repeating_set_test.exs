defmodule Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingSet
  alias Grizzly.CommandClass.ScheduleEntryLock

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 1,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 12,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0
        )

      assert %DailyRepeatingSet{
               user_id: 1,
               slot_id: 1,
               action: :enable,
               weekdays: [:monday, :friday],
               start_hour: 12,
               start_minute: 0,
               duration_hour: 1,
               duration_minute: 0
             } == command
    end

    test "encodes correctly" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x06
        )

      action_byte = ScheduleEntryLock.encode_enable_action(:enable)
      weekday_mask = ScheduleEntryLock.encode_weekdays([:monday, :friday])

      binary =
        <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x4E, 0x10, action_byte::size(8), 0x01, 0x02,
          weekday_mask::binary(), 0x09, 0x00, 0x01, 0x00>>

      assert {:ok, binary} == DailyRepeatingSet.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == DailyRepeatingSet.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x01,
          retries: 0
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               DailyRepeatingSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = DailyRepeatingSet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = DailyRepeatingSet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} =
        DailyRepeatingSet.init(
          user_id: 1,
          slot_id: 2,
          action: :enable,
          weekdays: [:monday, :friday],
          start_hour: 9,
          start_minute: 0,
          duration_hour: 1,
          duration_minute: 0,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = DailyRepeatingSet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = DailyRepeatingSet.init(value: :on)

      assert {:continue, _} = DailyRepeatingSet.handle_response(command, %{})
    end
  end
end
