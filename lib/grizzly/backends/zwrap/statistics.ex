defmodule Grizzly.Backends.Zwrap.Statistics do
  @moduledoc """
  Elixir aggregation of host application observations and native TX facts.

  `nodes` remains the host application's TX/RX view. `native_tx` is a separate,
  overlapping view of the core application pipeline, including native interviews
  and replies for valid unicast destinations. Never add these views together.
  Neither counts all on-air frames, security handshakes, NIFs or raw Serial API
  traffic, nor invents RF/IMA measurements. Counts describe observed events, not
  inferred in-flight work; subscription/reset/helper boundaries can omit starts.
  """
  use Agent

  def start_link(_), do: Agent.start_link(&empty/0, name: __MODULE__)

  defp empty(), do: %{coverage: :application_only, nodes: %{}, native_tx: native_empty()}
  defp native_empty(), do: %{coverage: :application_pipeline, nodes: %{}}

  def record(node, kind, details \\ nil) when node in 1..232 or node in 256..4000 do
    Agent.update(__MODULE__, fn stats ->
      current = Map.get(stats.nodes, node, %{rx: 0, tx_success: 0, tx_failure: 0, last_tx: nil})
      current = Map.update!(current, kind, &(&1 + 1))
      current = if details, do: Map.put(current, :last_tx, details), else: current
      put_in(stats.nodes[node], current)
    end)
  end

  @doc false
  def record_native(%{coverage: :application_pipeline, node_id: node, stage: stage} = fields)
      when node in 1..232 or node in 256..4000 do
    kind =
      case stage do
        :completed -> if fields[:status] in [:ok, :verified], do: :tx_success, else: :tx_failure
        stage when stage in [:queued, :started, :cancelled_queued, :abort_requested] -> stage
        _ -> nil
      end

    if kind do
      Agent.update(__MODULE__, fn stats ->
        current =
          Map.get(stats.native_tx.nodes, node, %{
            queued: 0,
            started: 0,
            tx_success: 0,
            tx_failure: 0,
            cancelled_queued: 0,
            abort_requested: 0,
            last_tx: nil
          })

        current = Map.update!(current, kind, &(&1 + 1))
        current = if stage == :completed, do: %{current | last_tx: fields}, else: current
        put_in(stats.native_tx.nodes[node], current)
      end)
    end

    :ok
  end

  def record_native(_), do: :ok

  def snapshot(), do: Agent.get(__MODULE__, & &1)
  def reset(), do: Agent.update(__MODULE__, fn _ -> empty() end)

  @doc false
  def transmission_stats(report) when is_map(report) do
    speed =
      case Enum.at(report[:last_used_route] || [], 4) do
        1 -> {9.6, :kbit_sec}
        2 -> {40, :kbit_sec}
        3 -> {100, :kbit_sec}
        _ -> nil
      end

    stats = [native_tx_report: report]
    if speed, do: Keyword.put(stats, :transmission_speed, speed), else: stats
  end
end
