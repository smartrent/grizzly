defmodule Grizzly.CommandClass.TimeParameters.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.TimeParameters.Set
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} =
        Set.init(
          value: %{
            year: 2019,
            month: 7,
            day: 3,
            hour: 1,
            minute: 2,
            second: 3
          }
        )

      assert %Set{
               value: %{
                 year: 2019,
                 month: 7,
                 day: 3,
                 hour: 1,
                 minute: 2,
                 second: 3
               }
             } == command
    end

    test "encodes correctly" do
      {:ok, command} =
        Set.init(
          value: %{
            year: 2019,
            month: 7,
            day: 3,
            hour: 1,
            minute: 2,
            second: 3
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
        0x8B,
        0x01,
        0x07,
        0xE3,
        0x07,
        0x03,
        0x01,
        0x02,
        0x03
      >>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} =
        Set.init(
          value: %{
            year: 2019,
            month: 17,
            day: 3,
            hour: 1,
            minute: 2,
            second: 3
          },
          seq_number: 0x06
        )

      error = EncodeError.new({:invalid_argument_value, :month, 17, Set})

      assert {:error, error} == Set.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} =
        Set.init(
          value: %{year: 2019, month: 7, day: 3, hour: 1, minute: 2, second: 3},
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} =
        Set.init(
          value: %{year: 2019, month: 7, day: 3, hour: 1, minute: 2, second: 3},
          seq_number: 0x01,
          retries: 0
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} =
        Set.init(
          value: %{year: 2019, month: 7, day: 3, hour: 1, minute: 2, second: 3},
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(value: :on)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
