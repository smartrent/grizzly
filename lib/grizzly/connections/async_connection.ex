defmodule Grizzly.Connections.AsyncConnection do
  @moduledoc false
  import Grizzly.NodeId, only: [is_zwave_node_id: 1]

  alias Grizzly.Connections

  @implementation if Application.compile_env(:grizzly, :backend, :zipgateway) == :zwrap,
                    do: Grizzly.Backends.Zwrap.Connection,
                    else: Grizzly.Backends.Zipgateway.AsyncConnection

  def child_spec(node, opts \\ []),
    do: @implementation.child_spec(node, Keyword.put(opts, :mode, :async))

  def start_link(options, node, opts \\ []),
    do: @implementation.start_link(options, node, Keyword.put(opts, :mode, :async))

  @spec send_command(GenServer.name() | Grizzly.node_id(), Grizzly.ZWave.Command.t(), keyword()) ::
          {:ok, reference()}
  def send_command(node_or_conn, command, opts \\ [])

  def send_command(node, command, opts) when is_zwave_node_id(node) or node == :gateway,
    do: send_command(via_name(node), command, opts)

  def send_command(connection, command, opts),
    do: GenServer.call(connection, {:send_command, command, opts}, 140_000)

  @spec stop_command(Grizzly.node_id() | pid(), reference()) :: :ok
  def stop_command(node, ref), do: GenServer.call(via_name(node), {:stop_command, ref})
  @spec request_alive?(Grizzly.node_id() | pid(), reference()) :: boolean()
  def request_alive?(node, ref), do: GenServer.call(via_name(node), {:request_alive?, ref})

  def stop(node) do
    GenServer.stop(via_name(node), :normal)
  catch
    :exit, {:noproc, _} -> :ok
  end

  defp via_name(pid) when is_pid(pid), do: pid
  defp via_name(node), do: Connections.via_name({:async, node})
end
