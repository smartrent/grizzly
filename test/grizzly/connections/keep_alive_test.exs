defmodule Grizzly.Connections.KeepAliveTest do
  use ExUnit.Case

  alias Grizzly.Connections.KeepAlive

  @tag :integration
  test "receive message after" do
    KeepAlive.init(2_000)

    assert_receive :keep_alive_tick, 2_100
  end

  @tag :integration
  test "resets the timer early" do
    ka = KeepAlive.init(2_000)

    :timer.sleep(1_000)

    new_ka = KeepAlive.timer_restart(ka)

    assert_receive :keep_alive_tick, 2_100
    refute new_ka.ref == ka.ref
  end

  @tag :integration
  test "stops keep alive" do
    ka = KeepAlive.init(2_000) |> KeepAlive.timer_clear()

    refute_receive :keep_alive_tick, 2_100
    assert ka.ref == nil
  end
end
