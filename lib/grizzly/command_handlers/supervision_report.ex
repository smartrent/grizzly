defmodule Grizzly.CommandHandlers.SupervisionReport do
  @moduledoc """
  This handler is used for non-get commands sent with Supervision.
  """
  @behaviour Grizzly.CommandHandler

  alias Grizzly.Report
  alias Grizzly.ZWave.Command

  @impl Grizzly.CommandHandler
  def init(_, opts) do
    state =
      opts
      |> Enum.into(%{})
      |> Map.take([:command_ref, :node_id, :session_id, :waiter, :status_updates?])

    {:ok, state}
  end

  @impl Grizzly.CommandHandler
  def handle_ack(state), do: {:continue, state}

  @impl Grizzly.CommandHandler
  def handle_command(%Command{name: :supervision_report} = command, state) do
    session_id = Command.param!(command, :session_id)
    status = Command.param!(command, :status)
    more_status_updates = Command.param!(command, :more_status_updates)

    cond do
      # ignore this report if the session ids do not match
      session_id != state.session_id ->
        {:continue, state}

      # some devices erroneously set the more_status_updates field to true,
      # so we'll consider success, fail, and no_support to be the final report
      # even if more_status_updates is true
      status in [:success, :fail, :no_support] or more_status_updates == :last_report ->
        {:complete, command}

      # more reports are coming
      true ->
        maybe_notify_waiter(command, state)
        {:continue, state}
    end
  end

  def handle_command(_command, state), do: {:continue, state}

  defp maybe_notify_waiter(command, %{waiter: {waiter_pid, _}, status_updates?: true} = state)
       when is_pid(waiter_pid) do
    send(
      waiter_pid,
      {:grizzly, :report,
       Report.new(:inflight, :supervision_status, state.node_id,
         command: command,
         command_ref: state.command_ref,
         acknowledged: true
       )}
    )
  end

  defp maybe_notify_waiter(_, _), do: :ok
end
