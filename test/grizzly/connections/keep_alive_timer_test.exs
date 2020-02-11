defmodule Grizzly.Connections.KeepAliveTimerTest do
  use ExUnit.Case

  alias Grizzly.Connections.KeepAliveTimer

  test "receive message after" do
    KeepAliveTimer.create(self(), 2_000)

    assert_receive :keep_alive_tick, 2_100
  end

  test "resets the timer early" do
    timer = KeepAliveTimer.create(self(), 2_000)

    :timer.sleep(1_000)

    KeepAliveTimer.restart(timer)

    assert_receive :keep_alive_tick, 2_100
  end

  test "cancels timer" do
    timer = KeepAliveTimer.create(self(), 2_000)
    KeepAliveTimer.cancel_timer(timer)
    refute_receive :keep_alive_tick, 2_100
  end
end
