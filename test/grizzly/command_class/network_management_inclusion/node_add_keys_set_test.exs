defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAddKeysSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInclusion.NodeAddKeysSet
  alias Grizzly.Command.EncodeError

  test "initalize command data" do
    opts = [
      seq_number: 0x01,
      grant_csa?: true,
      granted_keys: 0,
      accept_s2?: true
    ]

    assert {:ok, %NodeAddKeysSet{}} = NodeAddKeysSet.init(opts)
  end

  test "encode the command" do
    opts = [
      seq_number: 0x01,
      grant_csa?: true,
      granted_keys: [],
      accept_s2?: true
    ]

    {:ok, command} = NodeAddKeysSet.init(opts)
    expected_binary = Packet.header(1) <> <<0x34, 0x12, 0x1, 0x03, 0x00>>

    assert {:ok, expected_binary} == NodeAddKeysSet.encode(command)
  end

  test "encode the command incorrectly" do
    opts = [
      seq_number: 0x01,
      grant_csa?: :blue,
      granted_keys: [],
      accept_s2?: true
    ]

    {:ok, command} = NodeAddKeysSet.init(opts)

    error =
      EncodeError.new(
        {:invalid_argument_value, :grant_csa?, :blue,
         Grizzly.CommandClass.NetworkManagementInclusion.NodeAddKeysSet}
      )

    assert {:error, error} == NodeAddKeysSet.encode(command)
  end

  describe "handles responses" do
    test "handles when ack response happens" do
      opts = [
        seq_number: 0x01,
        grant_csa?: true,
        granted_keys: 0,
        accept_s2?: true
      ]

      {:ok, command} = NodeAddKeysSet.init(opts)
      packet = %Packet{seq_number: 0x01, types: [:ack_response]}

      assert {:continue, command} == NodeAddKeysSet.handle_response(command, packet)
    end

    test "handles when DSK report happens" do
      packet = %Packet{
        body: %{
          command: :node_add_dsk_report,
          input_length: 2,
          dsk: <<0x01, 0x03, 0x05>>
        }
      }

      opts = [
        seq_number: 0x01,
        grant_csa?: true,
        granted_keys: 0,
        accept_s2?: true
      ]

      {:ok, command} = NodeAddKeysSet.init(opts)

      expected_report_info = %{required_input_length: 2, dsk: <<0x01, 0x03, 0x05>>}

      assert {:done, {:dsk_report_info, expected_report_info}} ==
               NodeAddKeysSet.handle_response(command, packet)
    end
  end
end
