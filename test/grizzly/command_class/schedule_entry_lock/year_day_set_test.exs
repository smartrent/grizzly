defmodule Grizzly.CommandClass.ScheduleEntryLock.YearDaySet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock.YearDaySet
  alias Grizzly.CommandClass.ScheduleEntryLock
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
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
        )

      assert %YearDaySet{
               user_id: 2,
               slot_id: 1,
               action: :enable,
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
             } == command
    end

    test "encodes correctly" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x06
        )

      {:ok, action_byte} = ScheduleEntryLock.encode_enable_action(:enable)
      {:ok, year} = ScheduleEntryLock.encode_year(2019)

      binary = <<
        35,
        2,
        128,
        208,
        6,
        0,
        0,
        3,
        2,
        0,
        0x4E,
        0x06,
        action_byte::size(8),
        0x02,
        0x01,
        year,
        7,
        10,
        13,
        45,
        year,
        8,
        11,
        14,
        46
      >>

      assert {:ok, binary} == YearDaySet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 1066,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x06
        )

      error = EncodeError.new({:invalid_argument_value, :start_year, 1066, YearDaySet})

      assert {:error, error} == YearDaySet.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 1,
          slot_id: 2,
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == YearDaySet.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x01,
          retries: 0
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               YearDaySet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = YearDaySet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = YearDaySet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} =
        YearDaySet.init(
          user_id: 2,
          slot_id: 1,
          action: :enable,
          start_year: 2019,
          start_month: 7,
          start_day: 10,
          start_hour: 13,
          start_minute: 45,
          stop_year: 2019,
          stop_month: 8,
          stop_day: 11,
          stop_hour: 14,
          stop_minute: 46,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = YearDaySet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = YearDaySet.init(value: :on)

      assert {:continue, _} = YearDaySet.handle_response(command, %{})
    end
  end
end
