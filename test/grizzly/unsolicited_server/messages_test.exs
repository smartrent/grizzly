defmodule Grizzly.UnsolicitedServer.MessagesTest do
  use ExUnit.Case

  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, ZIPPacket}

  test "can subscribe and receive messages" do
    {:ok, receiving_command} = SwitchBinaryGet.new()
    :ok = Messages.subscribe(:switch_binary_get)
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(receiving_command, 0x02)

    Messages.broadcast(
      {0, 0, 0, 2},
      ZWave.to_binary(zip_packet)
    )

    assert_receive {:grizzly, :event, node_id, received_command}, 500

    assert node_id == 2
    assert receiving_command == receiving_command
  end
end
