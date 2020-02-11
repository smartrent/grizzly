defmodule Grizzly.UnsolicitedServer.MessagesTest do
  use ExUnit.Case

  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, ZIPPacket}

  test "can subscribe and receive messages" do
    {:ok, receiving_command} = SwitchBinaryGet.new()
    :ok = Messages.subscribe(:switch_binary_get)

    Messages.broadcast(
      {0, 0, 0, 2},
      ZIPPacket.to_binary(ZIPPacket.with_zwave_command(receiving_command, seq_number: 0x02))
    )

    assert_receive {:grizzly, :event, node_id, received_command}, 500

    assert node_id == 2
    assert receiving_command == receiving_command
  end
end
