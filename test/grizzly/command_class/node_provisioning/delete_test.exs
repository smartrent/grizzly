defmodule Grizzly.CommandClass.NodeProvisioning.DeleteTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Packet, DSK}
  alias Grizzly.CommandClass.NodeProvisioning.Delete
  alias Grizzly.Command.EncodeError

  setup do
    dsk = "50285-18819-09924-30691-15973-33711-04005-03623"

    {:ok, %{dsk: dsk}}
  end

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state", %{dsk: dsk} do
      {:ok, command} = Delete.init(dsk: dsk)

      assert %Delete{dsk: dsk} == command
    end

    test "encodes correctly with dsk", %{dsk: dsk} do
      {:ok, dsk_binary} = DSK.string_to_binary(dsk)
      {:ok, command} = Delete.init(dsk: dsk, seq_number: 0x06)

      binary =
        <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x78, 0x02, 0x06, 0x00::size(3),
          byte_size(dsk_binary)::size(5)>> <> dsk_binary

      assert {:ok, binary} == Delete.encode(command)
    end

    test "encodes correctly with no dsk" do
      {:ok, command} = Delete.init(dsk: nil, seq_number: 0x06)

      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x78, 0x02, 0x06, 0x00>>

      assert {:ok, binary} == Delete.encode(command)
    end

    test "errors when a dsk is too long", %{dsk: dsk} do
      bad_dsk = dsk <> "-12345"
      {:ok, command} = Delete.init(seq_number: 0x06, dsk: bad_dsk)

      assert {:error, %EncodeError{}} = Delete.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} = Delete.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Delete.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = Delete.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Delete.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Delete.init(seq_number: 0x01, retries: 2)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %Delete{}} = Delete.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Delete.init(seq_number: 0x01)

      assert {:continue, _} = Delete.handle_response(command, %{})
    end
  end
end
