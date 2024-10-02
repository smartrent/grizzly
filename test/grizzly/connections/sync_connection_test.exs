defmodule Grizzly.Connections.SyncConnectionTest do
  use ExUnit.Case

  alias Grizzly.{Connection, Report}
  alias Grizzly.Connections.SyncConnection
  alias Grizzly.ZWave.Commands.SwitchBinaryGet

  setup do
    # establish the connections for the tests
    {:ok, _} = Connection.open(100)
    {:ok, _} = Connection.open(101)
    {:ok, _} = Connection.open(102)

    :ok
  end

  test "handles nack responses" do
    {:ok, command} = SwitchBinaryGet.new()

    # 101 node_id will always return a nack_response
    assert {:ok, %Report{status: :complete, type: :nack_response, node_id: 101}} =
             SyncConnection.send_command(101, command)
  end

  test "handles queued responses" do
    {:ok, command} = SwitchBinaryGet.new()

    # 102 will always respond with nack waiting with 2 seconds
    assert {:ok,
            %Report{status: :inflight, type: :queued_delay, queued_delay: 2, queued: true} =
              report} = SyncConnection.send_command(102, command)

    ref = report.command_ref

    assert is_reference(ref)

    assert_receive {:grizzly, :report, %Report{command_ref: ^ref} = report}, 2_500

    assert report.command.name == :switch_binary_report
  end

  @tag :integration
  test "handle command that does not respond (timeout)" do
    {:ok, command} = SwitchBinaryGet.new()

    assert {:ok, %Report{type: :timeout, node_id: 100}} =
             SyncConnection.send_command(100, command, timeout: 1_000)
  end
end
