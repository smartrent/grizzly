defmodule Grizzly.ConnectionTest do
  use ExUnit.Case

  alias Grizzly.Connection

  test "open a connection" do
    assert {:ok, _connection} = Connection.open(1)
  end

  @tag :integration
  test "open a connections then close it and send a command - should auto reconnect" do
    # use 555 - as no other test needs 555 to be up and running
    {:ok, _} = Connection.open(555)
    :ok = Connection.close(555)

    # the send command should reconnect when trying to send a command and
    # work as if no connection closing happened.
    assert :ok == Grizzly.send_command(555, :switch_binary_set, target_value: :off)
  end
end
