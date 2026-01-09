defmodule Grizzly.Requests.Handlers.SupervisionReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.Requests.Handlers.SupervisionReport, as: Handler
  alias Grizzly.ZWave.Commands

  setup do
    ref = make_ref()

    {:ok, state} =
      Handler.init(nil,
        session_id: 1,
        waiter: {self(), nil},
        command_ref: ref,
        node_id: 1,
        status_updates?: false
      )

    %{state: state, command_ref: ref}
  end

  test "continues when receiving an ack", %{state: state} do
    assert {:continue, ^state} = Handler.handle_ack(state)
  end

  test "continues when session id does not match", %{state: state} do
    {:ok, command} =
      Commands.create(
        :supervision_report,
        more_status_updates: :last_report,
        status: :success,
        duration: :unknown,
        session_id: 10
      )

    assert {:continue, ^state} = Handler.handle_command(command, state)
  end

  test "continues when more_status_updates equals :more_reports", %{state: state} do
    {:ok, command} =
      Commands.create(
        :supervision_report,
        more_status_updates: :more_reports,
        status: :working,
        duration: :unknown,
        session_id: 1
      )

    assert {:continue, ^state} = Handler.handle_command(command, state)
  end

  test "completes when more_status_updates equals :last_report", %{state: state} do
    {:ok, command} =
      Commands.create(
        :supervision_report,
        more_status_updates: :last_report,
        status: :working,
        duration: :unknown,
        session_id: 1
      )

    assert {:complete, ^command} = Handler.handle_command(command, state)
  end

  test "sends non-final reports to command owner", %{state: state, command_ref: command_ref} do
    state = %{state | status_updates?: true}

    {:ok, update1} =
      Commands.create(
        :supervision_report,
        more_status_updates: :more_reports,
        status: :working,
        duration: :unknown,
        session_id: 1
      )

    assert {:continue, ^state} = Handler.handle_command(update1, state)

    {:ok, update2} =
      Commands.create(
        :supervision_report,
        more_status_updates: :more_reports,
        status: :working,
        duration: :unknown,
        session_id: 1
      )

    assert {:continue, ^state} = Handler.handle_command(update2, state)

    {:ok, final} =
      Commands.create(
        :supervision_report,
        more_status_updates: :last_report,
        status: :working,
        duration: :unknown,
        session_id: 1
      )

    assert {:complete, ^final} = Handler.handle_command(final, state)

    assert_receive {:grizzly, :report,
                    %Grizzly.Report{
                      command: ^update1,
                      command_ref: ^command_ref,
                      queued: false,
                      status: :inflight,
                      type: :supervision_status,
                      node_id: 1
                    }}

    assert_receive {:grizzly, :report,
                    %Grizzly.Report{
                      command: ^update2,
                      command_ref: ^command_ref,
                      queued: false,
                      status: :inflight,
                      type: :supervision_status,
                      node_id: 1
                    }}

    # shouldn't be any other messages
    refute_receive _
  end
end
