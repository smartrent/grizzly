defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAdd.Test do
  use ExUnit.Case, async: true

  alias Grizzly.{Node, Packet}
  alias Grizzly.CommandClass.NetworkManagementInclusion.NodeAdd

  describe "implements Grizzly.Command behaviour" do
    test "initializes the command" do
      assert {:ok, %NodeAdd{mode: :any_s2, tx_opts: 0x20, seq_number: 0x01}} =
               NodeAdd.init(seq_number: 0x01)
    end

    test "encodes correctly" do
      {:ok, command} = NodeAdd.init(seq_number: 0x09)
      binary = <<35, 2, 128, 208, 9, 0, 0, 3, 2, 0, 0x34, 0x01, 0x09, 0x00, 0x07, 0x20>>

      assert {:ok, binary} == NodeAdd.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = NodeAdd.init(seq_number: 0xA0)
      packet = Packet.new(seq_number: 0xA0, types: [:ack_response])

      assert {:continue, ^command} = NodeAdd.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = NodeAdd.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} = NodeAdd.handle_response(command, packet)
    end

    test "handle node add status report response" do
      report = %{
        command: :node_add_status,
        status: :done,
        node_id: 0x03,
        command_classes: [food: 1],
        basic_class: :pizza,
        generic_class: :yams,
        specific_class: :cookies,
        keys_granted: [:s0],
        listening?: false
      }

      zw_node =
        Node.new(
          id: report.node_id,
          command_classes: report.command_classes,
          security: :s0,
          basic_cmd_class: report.basic_class,
          generic_cmd_class: report.generic_class,
          specific_cmd_class: report.specific_class
        )

      packet = Packet.new(body: report)

      {:ok, command} = NodeAdd.init(seq_number: 0x14)
      assert {:done, {:ok, ^zw_node}} = NodeAdd.handle_response(command, packet)
    end

    test "hanldes node add keys report" do
      packet = %Packet{
        body: %{
          command: :node_add_keys_report,
          requested_keys: 3,
          csa?: false
        }
      }

      {:ok, command} = NodeAdd.init(seq_number: 0x01)

      expected_report_data = %{
        requested_keys: 3,
        csa?: false
      }

      assert {:send_message, {:node_add_keys_report, expected_report_data}, command} ==
               NodeAdd.handle_response(command, packet)
    end

    test "handle respones" do
      {:ok, command} = NodeAdd.init([])

      assert {:continue, ^command} = NodeAdd.handle_response(command, %{command: :llama})
    end
  end
end
