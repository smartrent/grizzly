defmodule Grizzly.ConnectionRegistry do
  @moduledoc false

  @spec via_name(Grizzly.node_id() | {:async, Grizzly.node_id()} | pid()) ::
          {:via, Registry, {__MODULE__, Grizzly.node_id()}} | pid()
  def via_name(pid) when is_pid(pid), do: pid

  def via_name(node_id) do
    {:via, Registry, {__MODULE__, node_id}}
  end
end
