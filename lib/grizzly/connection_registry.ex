defmodule Grizzly.ConnectionRegistry do
  @moduledoc false

  alias Grizzly.ZWave

  @type name() ::
          ZWave.node_id()
          | :gateway
          | {:async, ZWave.node_id()}
          | {:binary, ZWave.node_id(), pid()}

  @spec via_name(name()) ::
          {:via, Registry, {__MODULE__, Grizzly.node_id()}} | pid()
  def via_name(pid) when is_pid(pid), do: pid

  def via_name(node_id) do
    {:via, Registry, {__MODULE__, node_id}}
  end
end
