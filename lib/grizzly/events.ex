defmodule Grizzly.Events do
  @moduledoc """
  Pubsub registry for Grizzly events other than Z-Wave commands from devices.

  ## Events

  ### Ready
  This event is emitted when Z/IP Gateway has started and Grizzly is ready to
  process commands.

  ### OTW Firmware Update
  This event is emitted when updating the firmware on the Z-Wave module. The
  payload indicates the status. See `t:Grizzly.ZWaveFirmware.update_status/0`.

  ### Serial API Status
  This event is emitted when the serial API appears to be unresponsive (or recovers
  from this state) based on Z/IP Gateway's log output.
  """

  alias Grizzly.Report
  alias Grizzly.ZWave.Command

  import Grizzly.NodeId

  @type event :: :ready | :otw_firmware_update | :serial_api_status
  @type subject :: event() | Grizzly.command() | Grizzly.node_id() | {:node, Grizzly.node_id()}
  @type subscriptions :: [
          event: list(event()),
          commands: list(Grizzly.command()),
          nodes: list(Grizzly.node_id())
        ]

  @type subscribe_opt :: {:firehose, boolean()}
  @type subscribe_opts :: [subscribe_opt()]

  defguardp is_event(event) when event in [:ready, :otw_firmware_update, :serial_api_status]

  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(_) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  @doc """
  List a process's subscriptions.
  """
  @spec subscriptions(GenServer.server()) :: subscriptions()
  def subscriptions(pid \\ self()) do
    pid = if(is_pid(pid), do: pid, else: GenServer.whereis(pid))

    subscriptions =
      Registry.select(Grizzly.Events, [
        {
          {:"$1", :"$2", :_},
          [{:==, :"$2", pid}],
          [:"$1"]
        }
      ])

    subscriptions =
      for key <- subscriptions, reduce: [] do
        acc ->
          {type, key} =
            case key do
              {:node, node_id} -> {:nodes, node_id}
              e when is_event(e) -> {:events, e}
              c -> {:commands, c}
            end

          Keyword.update(acc, type, [key], fn current -> [key | current] end)
      end

    for {type, keys} <- subscriptions do
      {type, Enum.sort(keys)}
    end
  end

  @doc """
  Subscribe to an event, all commands from a node, or a specific command from any
  node.

  ## Options

  * `:firehose` - Normally, subscribers will only receive unsolicited commands
    from the node (or command) they are subscribed to. If this option is set to
    true, subscribers will receive all incoming commands that match, including
    responses to commands sent via `Grizzly.send_command/4`. Defaults to `false`.
  """
  @spec subscribe(subject() | [subject()], subscribe_opts()) :: :ok
  def subscribe(subject, opts \\ [])

  def subscribe([subject | subjects], opts) do
    subscribe(subject, opts)
    subscribe(subjects, opts)
  end

  def subscribe([], _opts), do: :ok

  def subscribe(event, _opts) when is_event(event) do
    _ = Registry.register(__MODULE__, key(event), [])
    :ok
  end

  def subscribe(subject, opts) do
    opts = opts |> Map.new() |> Map.take([:firehose])
    _ = Registry.register(__MODULE__, key(subject), opts)
    :ok
  end

  @doc """
  Unsubscribe from one or more Grizzly events.
  """
  @spec unsubscribe(subject() | [subject()]) :: :ok
  def unsubscribe(subject)

  def unsubscribe(node_id) when is_node_id(node_id),
    do: unsubscribe({:node, node_id})

  def unsubscribe(subjects) when is_list(subjects),
    do: Enum.each(subjects, &unsubscribe/1)

  def unsubscribe(subject) do
    _ = Registry.unregister(__MODULE__, subject)
    :ok
  end

  @doc false
  @spec broadcast_event(event(), term()) :: :ok
  def broadcast_event(event, payload) when is_event(event) do
    Registry.dispatch(__MODULE__, key(event), fn entries ->
      for {pid, _} <- entries do
        send(pid, {:grizzly, event, payload})
      end
    end)
  end

  @doc false
  @spec broadcast_report(Report.t()) :: :ok
  def broadcast_report(%Report{command: %Command{}} = report) do
    report
    |> __subs_for_report__()
    |> Enum.each(&send(&1, {:grizzly, :report, report}))
  end

  def broadcast_report(_), do: :ok

  @doc false
  @spec __subs_for_report__(Report.t()) :: [pid()]
  def __subs_for_report__(
        %Report{node_id: node_id, command: %Command{name: command_name}} = report
      ) do
    guards =
      if report.type == :unsolicited do
        match_spec_guards_for_unsolicited(node_id, command_name)
      else
        match_spec_guards_for_firehose(node_id, command_name)
      end

    subscribers =
      Registry.select(Grizzly.Events, [
        {
          {:"$1", :"$2", :"$3"},
          guards,
          [{{:"$1", :"$2", :"$3"}}]
        }
      ])

    # Reduce to a list of unique pids
    subscribers
    |> Enum.map(&elem(&1, 1))
    |> Enum.uniq()
  end

  defp match_spec_guards_for_unsolicited(node_id, command_name) do
    command_name_match = {:==, :"$1", key(command_name)}
    node_id_match = {:==, :"$1", key(node_id)}
    [{:orelse, command_name_match, node_id_match}]
  end

  defp match_spec_guards_for_firehose(node_id, command_name) do
    [key_match] = match_spec_guards_for_unsolicited(node_id, command_name)

    # erlang and elixir have opposite argument orders for map_get
    is_firehose = {:==, {:map_get, :firehose, :"$3"}, true}

    [{:andalso, key_match, is_firehose}]
  end

  defp key({:virtual, node_id}), do: "node:virtual:#{node_id}"
  defp key(key) when is_zwave_node_id(key), do: "node:#{key}"
  defp key(key) when is_event(key), do: "event:#{key}"
  defp key(key), do: "command:#{key}"
end
