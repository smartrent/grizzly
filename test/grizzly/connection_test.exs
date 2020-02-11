defmodule Grizzly.ConnectionTest do
  use ExUnit.Case

  alias Grizzly.Connection

  test "open a connection" do
    assert {:ok, _connection} = Connection.open(1)
  end
end
