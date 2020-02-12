defmodule Grizzly.CommandClass.NodeProvisioning.SetTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Packet, DSK}
  alias Grizzly.CommandClass.NodeProvisioning.Set
  alias Grizzly.Command.EncodeError

  setup do
    dsk = "50285-18819-09924-30691-15973-33711-04005-03623"
    meta_extensions = []
    {:ok, %{dsk: dsk, meta_extensions: meta_extensions}}
  end

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state", %{dsk: dsk, meta_extensions: meta_extensions} do
      {:ok, command} = Set.init(dsk: dsk, meta_extensions: meta_extensions)

      assert %Set{dsk: dsk, meta_extensions: meta_extensions} == command
    end

    test "encodes correctly", %{dsk: dsk, meta_extensions: meta_extensions} do
      {:ok, binary_dsk} = DSK.string_to_binary(dsk)
      {:ok, command} = Set.init(dsk: dsk, meta_extensions: meta_extensions, seq_number: 0x06)

      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x78, 0x01, 0x06, 0x10>> <> binary_dsk

      assert {:ok, binary} == Set.encode(command)
    end

    test "errors when dsk is too long", %{dsk: dsk, meta_extensions: meta_extensions} do
      {:ok, command} =
        Set.init(seq_number: 0x06, dsk: dsk <> "-12312", meta_extensions: meta_extensions)

      assert {:error, %EncodeError{}} = Set.encode(command)
    end

    test "errors when dsk is too short" do
      {:ok, command} = Set.init(seq_number: 0x06, dsk: "12345-12345", meta_extensions: [])

      assert {:error, %EncodeError{}} = Set.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} = Set.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = Set.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(seq_number: 0x01, retries: 2)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %Set{}} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(seq_number: 0x01)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
