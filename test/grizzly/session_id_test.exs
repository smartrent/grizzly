defmodule Grizzly.SessionIdTest do
  use ExUnit.Case, async: true

  setup do
    pid = start_supervised!({Grizzly.SessionId, seed: 12345, name: __MODULE__})
    %{pid: pid}
  end

  test "increments session ids per-node", %{pid: pid} do
    assert 13 == Grizzly.SessionId.get_and_inc(pid, 2)
    assert 14 == Grizzly.SessionId.get_and_inc(pid, 2)
    assert 15 == Grizzly.SessionId.get_and_inc(pid, 2)
    assert 22 == Grizzly.SessionId.get_and_inc(pid, 3)
    assert 23 == Grizzly.SessionId.get_and_inc(pid, 3)
    assert 25 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 26 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 27 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 28 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 29 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 30 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 31 == Grizzly.SessionId.get_and_inc(pid, 5)
    assert 0 == Grizzly.SessionId.get_and_inc(pid, 5)
  end
end
