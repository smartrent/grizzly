defmodule Grizzly.ZIPGateway.ReadyCheckerTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZIPGateway.ReadyChecker

  @report {:grizzly, :report,
           %Grizzly.Report{
             status: :complete,
             type: :unsolicited,
             node_id: 1,
             command: %{name: :node_list_report}
           }}

  test "ready? returns false when not ready", ctx do
    ready_checker = start_supervised!({ReadyChecker, [name: ctx.test]})

    refute ReadyChecker.ready?(ready_checker)

    send(ready_checker, @report)
    assert ReadyChecker.ready?(ready_checker)
  end

  test "notifies when ready", ctx do
    pid = self()

    on_ready = fn ->
      send(pid, :received_ready)
    end

    ready_checker = start_supervised!({ReadyChecker, [name: ctx.test, status_reporter: on_ready]})

    send(ready_checker, @report)
    assert_receive :received_ready, 1_000
  end

  test "exception in callback does not crash ReadyChecker", ctx do
    on_ready = fn ->
      raise "expected error"
    end

    ready_checker = start_supervised!({ReadyChecker, [name: ctx.test, status_reporter: on_ready]})
    send(ready_checker, @report)

    assert Process.alive?(ready_checker)
  end
end
