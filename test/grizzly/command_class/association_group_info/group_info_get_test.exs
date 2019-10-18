defmodule Grizzly.CommandClass.AssociationGroupInfo.GroupInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.AssociationGroupInfo.GroupInfoGet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %GroupInfoGet{}} = GroupInfoGet.init([])
    end

    test "encodes correctly for one group" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x08, group: 0x02)

      binary =
        <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x59, 0x03, 0x00::size(1), 0x00::size(1),
          0x00::size(6), 0x02>>

      assert {:ok, binary} == GroupInfoGet.encode(command)
    end

    test "encodes correctly for all groups" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x08, group: nil)

      binary =
        <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x59, 0x03, 0x00::size(1), 0x01::size(1),
          0x00::size(6), 0x00>>

      assert {:ok, binary} == GroupInfoGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = GroupInfoGet.init(group: :fizzbuzz, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :group, :fizzbuzz, GroupInfoGet})

      assert {:error, error} == GroupInfoGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x10, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %GroupInfoGet{}} = GroupInfoGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x10, retries: 0, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == GroupInfoGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x10, group: 0x02)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = GroupInfoGet.handle_response(command, packet)
    end

    test "handles group name report responses" do
      report = %{
        command_class: :association_group_info,
        command: :groups_info_report,
        value: %{
          dynamic: true,
          groups_info: [
            %{group: 1, profile: :general_lifeline},
            %{group: 2, profile: :sensor_humidity}
          ]
        }
      }

      {:ok, command} = GroupInfoGet.init(group: nil, seq_number: 0x01)
      packet = Packet.new(body: report)

      assert {:done,
              {:ok,
               %{
                 dynamic: true,
                 groups_info: [
                   %{group: 1, profile: :general_lifeline},
                   %{group: 2, profile: :sensor_humidity}
                 ]
               }}} ==
               GroupInfoGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x01, group: 0x02)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = GroupInfoGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = GroupInfoGet.init(seq_number: 0x01, group: 0x02)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = GroupInfoGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = GroupInfoGet.init(group: 0x02)

      assert {:continue, %GroupInfoGet{group: 0x02}} ==
               GroupInfoGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
