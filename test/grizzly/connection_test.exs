defmodule Grizzly.ConnectionTest do
  use ExUnit.Case

  alias Grizzly.Connection
  alias Grizzly.Report

  test "open a connection" do
    assert {:ok, _connection} = Connection.open(1200)
  end

  @tag :integration
  test "open a connections then close it and send a command - should auto reconnect" do
    # use 555 - as no other test needs 555 to be up and running
    {:ok, _} = Connection.open(555)
    :ok = Connection.close(555)

    # the send command should reconnect when trying to send a command and
    # work as if no connection closing happened.
    assert {:ok, %Report{status: :complete, type: :ack_response, node_id: 555}} =
             Grizzly.send_command(555, :switch_binary_set, target_value: :off)
  end
end
