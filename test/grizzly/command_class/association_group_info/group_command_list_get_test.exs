defmodule Grizzly.CommandClass.AssociationGroupInfo.GroupCommandListGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.AssociationGroupInfo.GroupCommandListGet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %GroupCommandListGet{}} = GroupCommandListGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x08, group: 0x02)

      binary =
        <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x59, 0x05, 0x01::size(1), 0x00::size(7), 0x02>>

      assert {:ok, binary} == GroupCommandListGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = GroupCommandListGet.init(group: :fizzbuzz, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :group, :fizzbuzz, GroupCommandListGet})

      assert {:error, error} == GroupCommandListGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x10, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %GroupCommandListGet{}} =
               GroupCommandListGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x10, retries: 0, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               GroupCommandListGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x10, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = GroupCommandListGet.handle_response(command, packet)
    end

    test "handles group name report responses" do
      report = %{
        command_class: :association_group_info,
        command: :group_command_list_report,
        value: %{
          group: 2,
          command_list: [
            %{command_class: :association, command: :set},
            %{command_class: :battery, command: :get}
          ]
        }
      }

      {:ok, command} = GroupCommandListGet.init(group: 2, seq_number: 0x01)
      packet = Packet.new(body: report)

      assert {:done,
              {:ok,
               %{
                 group: 2,
                 command_list: [
                   %{command_class: :association, command: :set},
                   %{command_class: :battery, command: :get}
                 ]
               }}} ==
               GroupCommandListGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x01, group: 0x02)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = GroupCommandListGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = GroupCommandListGet.init(seq_number: 0x01, group: 0x02)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = GroupCommandListGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = GroupCommandListGet.init(group: 0x02)

      assert {:continue, %GroupCommandListGet{group: 0x02}} ==
               GroupCommandListGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
