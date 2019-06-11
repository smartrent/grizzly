defmodule Grizzly.Conn.Server.Test do
  use ExUnit.Case

  alias Grizzly.Conn.Server, as: ConnServer
  alias Grizzly.Conn.Config

  setup do
    config =
      :grizzly
      |> Application.get_env(Grizzly.Controller)
      |> Keyword.put(:heart_beat_timer, 2_000)
      |> Config.new()

    {:ok, conn} = ConnServer.start_link(config)

    {:ok, %{conn: conn}}
  end

  test "handles sending the heart beat after x amount of time", %{conn: conn} do
    :erlang.trace(conn, true, [:receive])
    :timer.sleep(3_000)

    assert_receive {:trace, ^conn, :receive, :heart_beat}
  end

  test "keeps the heart beat running after the first one", %{conn: conn} do
    :erlang.trace(conn, true, [:receive])
    :timer.sleep(3_200)

    assert_receive {:trace, ^conn, :receive, :heart_beat}

    :timer.sleep(3_200)
    assert_receive {:trace, ^conn, :receive, :heart_beat}
  end
end
