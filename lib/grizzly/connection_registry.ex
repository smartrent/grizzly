defmodule Grizzly.ConnectionRegistry do
  @moduledoc false

  alias Grizzly.Node

  @spec via_name(Node.node_id() | pid()) :: {:via, Registry, {__MODULE__, Node.node_id()}} | pid()
  def via_name(pid) when is_pid(pid), do: pid

  def via_name(node_id) do
    {:via, Registry, {__MODULE__, node_id}}
  end
end
