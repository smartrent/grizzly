defmodule Grizzly.CommandClass.NodeProvisioning.ListIterationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NodeProvisioning.ListIterationGet

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %ListIterationGet{}} = ListIterationGet.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      {:ok, command} = ListIterationGet.init(seq_number: 0x08, remaining_counter: 3)

      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x78, 0x03, 0x08, 0x03>>

      assert {:ok, binary} == ListIterationGet.encode(command)
    end

    test "does not encode too big remaining counter" do
      {:ok, command} = ListIterationGet.init(seq_number: 0x08, remaining_counter: 1024)

      assert {:error, %Grizzly.Command.EncodeError{}} = ListIterationGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = ListIterationGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:continue, ^command} = ListIterationGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = ListIterationGet.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               ListIterationGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = ListIterationGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %ListIterationGet{}} = ListIterationGet.handle_response(command, packet)
    end

    test "handles node provisioning list iteration report" do
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

      {:ok, command} = ListIterationGet.init(seq_number: 0x08)
      packet = Packet.new(body: report)

      assert {:done, {:ok, value}} == ListIterationGet.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = ListIterationGet.init([])

      assert {:continue, ^command} = ListIterationGet.handle_response(command, %{value: 100})
    end
  end
end
