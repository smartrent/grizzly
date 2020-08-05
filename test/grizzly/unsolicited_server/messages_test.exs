defmodule Grizzly.UnsolicitedServer.MessagesTest do
  use ExUnit.Case

  alias Grizzly.{Report, ZWave}
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, ZIPPacket}
  alias Grizzly.UnsolicitedServer.Messages

  test "can subscribe and receive messages" do
    {:ok, receiving_command} = SwitchBinaryGet.new()
    # report = Report.new(:complete, :unsolicited, 2, command: receiving_command)
    :ok = Messages.subscribe(:switch_binary_get)
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(receiving_command, 0x02)

    Messages.broadcast(
      {0, 0, 0, 2},
      ZWave.to_binary(zip_packet)
    )

    assert_receive {:grizzly, :report, %Report{} = report}, 500

    assert report.node_id == 2
    assert report.type == :unsolicited

    assert report.command == receiving_command
  end
end
