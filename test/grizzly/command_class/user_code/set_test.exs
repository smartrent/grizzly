defmodule Grizzly.CommandClass.UserCode.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.UserCode.Set
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Set{}} = Set.init([])
    end

    test "encodes" do
      {:ok, command} =
        Set.init(
          slot_id: 1,
          slot_status: :occupied,
          user_code: "1234",
          seq_number: 10
        )

      binary =
        <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x63, 0x01, 0x01, 0x01, 0x31, 0x32, 0x33, 0x34>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} =
        Set.init(
          slot_id: 1,
          slot_status: :occupied,
          user_code: "1234Z",
          seq_number: 10
        )

      error = EncodeError.new({:invalid_argument_value, :user_code, "1234Z", Set})

      assert {:error, error} == Set.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Set.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])
      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Set.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:retry, _command} = Set.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = Set.init([])

      assert {:continue, ^command} = Set.handle_response(command, %{code: 1})
    end
  end
end
