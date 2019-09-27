defmodule Grizzly.CommandClass.MultiChannelAssociation.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.MultiChannelAssociation.Get

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %Get{}} = Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x8E, 0x02, 0x03>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %Get{}} = Get.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = Get.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :multi_channel_association,
        command: :multi_channel_association_report,
        value: %{
          group: 0x03,
          max_nodes_supported: 0x08,
          nodes: [2, 3],
          endpoints: [
            %{node_id: 2, endpoint: 2},
            %{node_id: 3, endpoint: 3},
            %{node_id: 3, endpoint: 4}
          ],
          reports_to_follow: 0
        }
      }

      {:ok, command} = Get.init(group: 0x03)
      packet = Packet.new(body: report)

      assert {:done,
              {:ok,
               %{
                 group: 0x03,
                 max_nodes_supported: 0x08,
                 nodes: [2, 3],
                 endpoints: [
                   %{node_id: 2, endpoint: 2},
                   %{node_id: 3, endpoint: 3},
                   %{node_id: 3, endpoint: 4}
                 ]
               }}} ==
               Get.handle_response(command, packet)
    end

    test "handles incomplete report responses" do
      report = %{
        command_class: :multi_channel_association,
        command: :multi_channel_association_report,
        value: %{
          group: 0x03,
          max_nodes_supported: 0x08,
          nodes: [2, 3],
          endpoints: [
            %{node_id: 2, endpoint: 2},
            %{node_id: 3, endpoint: 3},
            %{node_id: 3, endpoint: 4}
          ],
          reports_to_follow: 1
        }
      }

      {:ok, command} = Get.init(group: 0x03)
      packet = Packet.new(body: report)

      buffered_command = %Get{
        command
        | buffer: %{
            nodes: [2, 3],
            endpoints: [
              %{node_id: 2, endpoint: 2},
              %{node_id: 3, endpoint: 3},
              %{node_id: 3, endpoint: 4}
            ]
          }
      }

      assert {:continue, buffered_command} ==
               Get.handle_response(command, packet)
    end

    test "handles completing report responses" do
      report = %{
        command_class: :multi_channel_association,
        command: :multi_channel_association_report,
        value: %{
          group: 0x03,
          max_nodes_supported: 0x08,
          nodes: [4],
          endpoints: [
            %{node_id: 4, endpoint: 1}
          ],
          reports_to_follow: 0
        }
      }

      {:ok, command} =
        Get.init(
          group: 0x03,
          buffer: %{
            nodes: [2, 3],
            endpoints: [
              %{node_id: 2, endpoint: 2},
              %{node_id: 3, endpoint: 3},
              %{node_id: 3, endpoint: 4}
            ]
          }
        )

      packet = Packet.new(body: report)

      assert {:done,
              {:ok,
               %{
                 group: 0x03,
                 max_nodes_supported: 0x08,
                 nodes: [2, 3, 4],
                 endpoints: [
                   %{node_id: 2, endpoint: 2},
                   %{node_id: 3, endpoint: 3},
                   %{node_id: 3, endpoint: 4},
                   %{node_id: 4, endpoint: 1}
                 ]
               }}} ==
               sort(Get.handle_response(command, packet))
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Get.init(group: 0x03, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = Get.init(group: 0x03)

      assert {:continue, %Get{group: 3}} ==
               Get.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end

  defp sort(
         {:done,
          {:ok,
           %{
             group: group,
             max_nodes_supported: max_nodes_supported,
             nodes: nodes,
             endpoints: endpoints
           }}}
       ) do
    {:done,
     {:ok,
      %{
        group: group,
        max_nodes_supported: max_nodes_supported,
        nodes: Enum.sort(nodes),
        endpoints:
          Enum.sort(
            endpoints,
            &(&1.node_id * 100 + &1.endpoint <= &2.node_id * 100 + &2.endpoint)
          )
      }}}
  end
end
