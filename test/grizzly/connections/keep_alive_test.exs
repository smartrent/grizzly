defmodule Grizzly.Connections.KeepAliveTest do
  use ExUnit.Case, async: true

  alias Grizzly.Connections.KeepAlive

  test "receive message after" do
    KeepAlive.init(1, 100)

    assert_receive :keep_alive_tick, 200
  end

  test "resets the timer early" do
    ka = KeepAlive.init(1, 500)

    :timer.sleep(300)

    # reset the timer
    new_ka = KeepAlive.timer_restart(ka)
    # ensure the old timer was canceled
    assert false == Process.read_timer(ka.ref)

    :timer.sleep(250)
    # it's ~550ms since the original init, but because of the reset, we
    # should not have any messages
    refute_received :keep_alive_tick

    # but we should get a message in another ~250ms
    assert_receive :keep_alive_tick, 300
    refute new_ka.ref == ka.ref
  end

  test "stops keep alive" do
    ka = KeepAlive.init(1, 250) |> KeepAlive.timer_clear()

    refute_receive :keep_alive_tick, 300
    assert ka.ref == nil
  end
end
