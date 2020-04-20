defmodule Grizzly.Connections.AsyncConnectionTest do
  use ExUnit.Case

  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.CommandHandlers.AckResponse
  alias Grizzly.ZWave.Commands.SwitchBinaryGet

  test "can stop a running command" do
    {:ok, _async_conn} = AsyncConnection.start_link(400)
    {:ok, command} = SwitchBinaryGet.new()

    {:ok, command_ref} = AsyncConnection.send_command(400, command, handler: AckResponse)

    :ok = AsyncConnection.stop_command(400, command_ref)

    refute AsyncConnection.command_alive?(400, command_ref)
  end

  @tag :timeout
  test "gets a timeout for the async command" do
    {:ok, _async_conn} = AsyncConnection.start_link(400)
    {:ok, command} = SwitchBinaryGet.new()

    {:ok, command_ref} =
      AsyncConnection.send_command(400, command, timeout: 1_000, handler: AckResponse)

    assert_receive {:grizzly, :send_command, {:error, :timeout, timeout_ref}}, 2_000

    assert command_ref == timeout_ref
  end
end
