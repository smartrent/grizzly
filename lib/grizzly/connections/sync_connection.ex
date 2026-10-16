defmodule Grizzly.Connections.SyncConnection do
  @moduledoc false
  alias Grizzly.Connections

  @implementation if Application.compile_env(:grizzly, :backend, :zipgateway) == :zwrap,
                    do: Grizzly.Backends.Zwrap.Connection,
                    else: Grizzly.Backends.Zipgateway.SyncConnection

  @type send_opt() :: {:timeout, non_neg_integer()} | {:retries, non_neg_integer()}

  def child_spec(node, opts \\ []),
    do: @implementation.child_spec(node, Keyword.put(opts, :mode, :sync))

  def start_link(options, node, opts \\ []),
    do: @implementation.start_link(options, node, Keyword.put(opts, :mode, :sync))

  @spec send_command(Grizzly.node_id() | pid(), Grizzly.ZWave.Command.t(), keyword()) ::
          Grizzly.send_command_response()
  def send_command(node, command, opts \\ []),
    do: GenServer.call(Connections.via_name(node), {:send_command, command, node, opts}, 140_000)

  @spec close(Grizzly.node_id() | pid()) :: :ok
  def close(node), do: GenServer.stop(Connections.via_name(node), :normal)
end
