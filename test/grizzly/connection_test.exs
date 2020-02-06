defmodule Grizzly.ConnectionTest do
  use ExUnit.Case

  alias Grizzly.Connection
  alias Grizzly.Commands.SwitchBinarySet

  setup do
    socket_opts = [host: {0, 0, 0, 0}, port: 5_001, transport: Grizzly.Transport.UDP]
    :ok = Connection.open(1, socket_opts)

    :ok
  end

  test "can send binary" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    assert :ok == Connection.send_command(1, command)
  end

  test "can close the connection" do
    assert :ok == Connection.close(1)
  end
end
