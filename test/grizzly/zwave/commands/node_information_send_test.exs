defmodule Grizzly.ZWave.Commands.NodeInformationSendTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NodeInformationSend

  test "creates the command and validates params" do
    assert {:ok, command} =
             Commands.create(:node_information_send,
               seq_number: 1,
               destination_node_id: 1,
               tx_options: [:ack]
             )

    assert command.command_byte == 0x05
  end

  test "encodes params correctly" do
    {:ok, command} =
      Commands.create(
        :node_information_send,
        seq_number: 10,
        destination_node_id: 15,
        tx_options: [:explore, :no_route, :low_power, :ack]
      )

    assert <<0x0A, 0x00, 0x0F, 0x33>> == NodeInformationSend.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary = <<0x0A, 0x00, 0x0F, 0x33>>

    assert {:ok, params} = NodeInformationSend.decode_params(nil, binary)
    assert params[:seq_number] == 10
    assert params[:destination_node_id] == 15
    assert :ack in params[:tx_options]
    assert :no_route in params[:tx_options]
    assert :low_power in params[:tx_options]
    assert :explore in params[:tx_options]
  end
end
