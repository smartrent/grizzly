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
    Grizzly.Events.subscribe(:ready)
    ready_checker = start_supervised!({ReadyChecker, [name: ctx.test]})

    refute ReadyChecker.ready?(ready_checker)
    refute_receive {:grizzly, :ready, _}

    send(ready_checker, @report)
    assert ReadyChecker.ready?(ready_checker)
    assert_receive {:grizzly, :ready, true}
  end

  test "notifies when ready", ctx do
    Grizzly.Events.subscribe(:ready)
    ready_checker = start_supervised!({ReadyChecker, [name: ctx.test]})

    send(ready_checker, @report)
    assert_receive {:grizzly, :ready, true}
  end
end
