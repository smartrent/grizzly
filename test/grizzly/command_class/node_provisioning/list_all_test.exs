defmodule Grizzly.CommandClass.NodeProvisioning.ListAllTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NodeProvisioning.ListAll

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %ListAll{}} = ListAll.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      {:ok, command} = ListAll.init(seq_number: 0x08)

      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x78, 0x03, 0x08, 0xFF>>

      assert {:ok, binary} == ListAll.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = ListAll.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:continue, ^command} = ListAll.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = ListAll.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               ListAll.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = ListAll.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %ListAll{}} = ListAll.handle_response(command, packet)
    end

    test "handles node provisioning list iteration" do
      value = %{
        seq_number: 8,
        remaining_count: 2,
        dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
      }

      report = %{
        command_class: :node_provisioning,
        command: :list_iteration_report,
        value: value
      }

      {:ok, command} = ListAll.init(seq_number: 0x08)
      packet = Packet.new(body: report)

      updated_command = %{
        command
        | remaining_counter: 2,
          __buffer: [Map.drop(value, ~w(remaining_count seq_number)a) | command.__buffer]
      }

      assert {:retry, updated_command} == ListAll.handle_response(command, packet)
    end

    test "handles node provisioning list end of iteration" do
      value = %{
        seq_number: 8,
        remaining_count: 0,
        dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
      }

      report = %{
        command_class: :node_provisioning,
        command: :list_iteration_report,
        value: value
      }

      {:ok, command} = ListAll.init(seq_number: 0x08)
      packet = Packet.new(body: report)

      assert {:done, {:ok, [Map.drop(value, ~w(remaining_count seq_number)a)]}} ==
               ListAll.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = ListAll.init([])

      assert {:continue, ^command} = ListAll.handle_response(command, %{value: 100})
    end
  end
end
