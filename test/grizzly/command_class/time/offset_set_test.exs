defmodule Grizzly.CommandClass.Time.OffsetSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Time.OffsetSet

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} =
        OffsetSet.init(
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
        )

      assert %OffsetSet{
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
             } == command
    end

    test "encodes correctly" do
      {:ok, command} =
        OffsetSet.init(
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
          },
          seq_number: 0x06
        )

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
        0x8A,
        0x05,
        0x1::size(1),
        4::size(7),
        0,
        0x0::size(1),
        60::size(7),
        3,
        10,
        2,
        11,
        3,
        2
      >>

      assert {:ok, binary} == OffsetSet.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} =
        OffsetSet.init(
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
          },
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == OffsetSet.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} =
        OffsetSet.init(
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
          },
          seq_number: 0x01,
          retries: 0
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == OffsetSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} =
        OffsetSet.init(
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
          },
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = OffsetSet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = OffsetSet.init(value: :on)

      assert {:continue, _} = OffsetSet.handle_response(command, %{})
    end
  end
end
