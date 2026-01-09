defmodule Grizzly.Connections.AsyncConnectionTest do
  use ExUnit.Case, async: true

  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.Requests.Handlers.AckResponse
  alias Grizzly.ZWave.Commands

  test "can stop a running command" do
    {:ok, conn} =
      AsyncConnection.start_link(GrizzlyTest.Utils.default_options(), 400, unnamed: true)

    {:ok, command} = Commands.create(:switch_binary_get)

    {:ok, command_ref} = AsyncConnection.send_command(conn, command, handler: AckResponse)

    :ok = AsyncConnection.stop_command(conn, command_ref)

    refute AsyncConnection.request_alive?(conn, command_ref)
  end

  @tag :integration
  test "gets a timeout for the async command" do
    {:ok, conn} =
      AsyncConnection.start_link(GrizzlyTest.Utils.default_options(), 400, unnamed: true)

    {:ok, command} = Commands.create(:switch_binary_get)

    {:ok, command_ref} =
      AsyncConnection.send_command(conn, command, timeout: 100, handler: AckResponse)

    assert_receive {:grizzly, :report, report}, 2_000

    assert report.command_ref == command_ref
  end
end
