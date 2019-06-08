defmodule Grizzly.Conn.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Conn
  alias Grizzly.Conn.Config
  alias Grizzly.Test.Client

  test "Passing a connection config to connect will connect and make a new connection" do
    config = Config.new(ip: {0, 0, 0, 0}, port: 5000, client: Client)
    %Conn{conn: conn} = Conn.open(config)
    assert is_pid(conn)
  end
end
