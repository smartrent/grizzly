defmodule Grizzly.Report do
  @moduledoc """
  Reports from Z-Wave commands

  When you send a command in Z-Wave you will receive a report back.

  ## When Things Go Well

  There are two primary reports that are returned when sending a command.

  The first is `:command` report and the second is an `:ack_response` report.
  These both will have a status of `:complete`.

  Normally, an `:ack_response` report is returned when you set a value on a
  device. This means the device received the command and is processing it,
  not that the device has already processed it. You might have to go read the
  value back after setting it if you want to make the device ran the set
  based command.

  A `:command` report type is returned often after reading a value from a
  device. This report will have its `:command` field filled with a Z-Wave
  command.

  ```elixir
  case Grizzly.send_command(node_id, command, command_args, command_opts) do
    {:ok, %Grizzly.Report{status: :complete, type: :command} = report} ->
      # do something withe report.command
    {:ok, %Grizzly.Report{status: :complete, type: :ack_response}} ->
      # do whatever
  end
  ```

  ## Queued Commands

  When sending a command to a device that sleeping, normally battery powered
  devices, the command will be queued internally. The command will still be
  considered `:inflight` as it has not reached the device yet. You know when
  a command has been queued when the report's `:status` field is `:inflight`
  and the `:type` field is `:queued_delayed`. Fields to help you manage queued
  commands are `:command_ref`, `:queued_delay`, and `:node_id`

  During the command's queued lifetime the system sends pings back to the
  caller to ensure that the low level connection is still established. This
  also provides an updated delayed time before the device wakes up.

  ```elixir
  case Grizzly.send_command(node_id, command, command_args, command_opts) do
    {:ok, %Grizzly.Report{status: :inflight, type: :queued_delay}} ->
      # the command was just queued
  end
  ```

  Once the command has been queued the calling process will receive messages
  about the queued command like so:

  ```elixir
  {:grizzly, :report, %Report{}}
  ```

  This report can take two forms. One for a completed queued command and one
  for a queued ping.


  ```elixir
  def handle_info({:grizzly, :report, report}, state) do
    case report do
      %Grizzly.Report{status: :inflight, type: :queued_ping} ->
        # handle the ping if you want
        # an updated queue delay will be found in the :queued_delay
        # field of the report
      %Grizzly.Report{status: :complete, type: :command, queued: true} ->
        # here if the :queued field is marked has true and the report is
        # complete that will indicate a command has made it to the sleeping
        # device and the device has received the command
      %Grizzly.Report{status: :complete, type: :timeout, queued: true} ->
        # The woke up and the controller sent the command but for reason
        # the command's processing timed out
    end
  end
  ```

  ## Timeouts

  If sending the command times out you will get a command with the `:type` of
  `:timeout`

  ```elixir
  case Grizzly.send_command(node_id, command, command_args, command_opts) do
    {:ok, %Grizzly.Report{status: :complete, type: :timeout}} ->
      # handle the timeout
  end
  ```

  The reason why this is considered okay is because the command that was sent
  was valid and we were able to establish a connect to the desired device but
  it just did not provide any report back.

  ## Full Example

  The below example shows the various ways one might match after calling
  `Grizzly.send_command/4`.

  ```elixir
  case Grizzly.send_command(node_id, command, command_args, command_opts) do
    {:ok, %Grizzly.Report{status: :complete, type: :command} = report} ->
      handle_complete_report(report)
    {:ok, %Grizzly.Report{status: :complete, type: :ack_response} = report} ->
      handle_complete_report(report)
    {:ok, %Grizzly.Report{status: :complete, type: :timeout} = report} ->
      handle_timeout(report)
    {:ok, %Grizzly.Report{status: :inflight, type: :queued} = report} ->
      handle_queued_command(report)
  end
  ```

  note: the `handle_*` functions will need to implemented and are only used in
  the example for illustration purposes
  """

  alias Grizzly.VirtualDevices
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @typedoc """
  All the data for the status and type of a report.

  Fields

    - `:status` - this indicates if the report is complete, inflight, or
      timed out
    - `:type` - this indicates if the report is contains a command or information
      about being queued.
    - `:command` - if the status is `:complete` and the type is `:command` then
      this field will contain a Z-Wave command in the report.
    - `:transmission_stats` - provides transmission stats for the command that
      was sent
    - `:queued_delay` - the delay time remaining if the report type is
      `:queued_delay` or `:queued_ping`
    - `:command_ref` - a reference to the command. This is mostly useful for
      tracking queued commands
    - `:node_id` - the node the report is responding from
    - `:queued` - this flag marks if the command was ever queued before
      completing
    - `:acknowledged` - whether the destination node acknowledged the command.
      Only valid when the status is `:complete`. For commands using the `AckResponse`
      command handler, this field will be true if `type` is `:ack_response` and false
      if `type` is `:nack_response`. For other command handlers, it will be true
      if the original command was acknowledged by the destination node (i.e. we
      received an ACK Response from Z/IP Gateway). This is useful for differentiating
      report timeouts where the destination received the command but didn't send
      a report (e.g. it doesn't support the command or command version, it considered
      some or all of the payload invalid, etc.) from other causes. Other types of
      timeouts typically mean the timeout was too short and Grizzly had to return
      before Z/IP Gateway could send a response
  """
  @type t() :: %__MODULE__{
          status: status(),
          type: type(),
          acknowledged: boolean(),
          command: Command.t() | nil,
          transmission_stats: [transmission_stat()],
          queued_delay: non_neg_integer(),
          command_ref: reference() | nil,
          node_id: Grizzly.node_id(),
          queued: boolean()
        }

  @type type() ::
          :ack_response
          | :nack_response
          | :queue_full
          | :command
          | :queued_ping
          | :unsolicited
          | :queued_delay
          | :timeout
          | :supervision_status

  @type status() :: :inflight | :complete

  @type opt() ::
          {:transmission_stats, [transmission_stat()]}
          | {:queued_delay, non_neg_integer()}
          | {:command, Command.t()}
          | {:command_ref, reference()}
          | {:queued, boolean()}
          | {:acknowledged, boolean()}

  @typedoc """
  The RSSI value between each device that command had to route through to get
  to the destination node

  If the value is `:not_available` that means data for that hop in not available
  or a hope did not take place. To see the nodes that the command was routed
  through see the `:last_working_route` field of the transmission stats.
  """
  @type rssi_value() :: integer() | :not_available

  @type transmit_speed() :: float() | non_neg_integer()

  @typedoc """
  The various transmission stats that are provide by the Z-Wave network when
  sending a command.

    - `:transmit_channel` - the RF channel the command was transmitted on
    - `:ack_channel` - the RF channel the acknowledgement report was
      transmitted on
    - `:rssi` - a 5 tuple that contains RSSI values for each hop in the Z-Wave
      network
    - `:last_working_route` - this contains a 4 tuple that shows what nodes the
      Z-Wave command was routed through to the destination node. Also this
      contains the speed by which the Z-Wave command was transmitted to the
      destination
    - `:transmission_time` - the length of time until the reception of an
      acknowledgement in milliseconds
    - `:route_changed` - this indicates if the route was changed for the
      current transmission
  """
  @type transmission_stat() ::
          {:transmit_channel, non_neg_integer()}
          | {:ack_channel, non_neg_integer()}
          | {:rssi_hops, [rssi_value()]}
          | {:rssi_4bars, 0..4 | :unknown}
          | {:rssi_dbm, rssi_value()}
          | {:last_working_route, [ZWave.node_id()]}
          | {:transmit_speed, transmit_speed()}
          | {:transmission_time, non_neg_integer()}
          | {:route_changed, boolean()}

  @enforce_keys [:status, :type, :node_id]
  defstruct status: nil,
            command: nil,
            transmission_stats: [],
            queued_delay: 0,
            command_ref: nil,
            node_id: nil,
            type: nil,
            queued: false,
            acknowledged: false

  @doc """
  Make a new `Grizzly.Report`
  """
  @spec new(status(), type(), ZWave.node_id() | VirtualDevices.id(), [opt()]) :: t()
  def new(status, type, node_id, opts \\ []) do
    %__MODULE__{
      status: status,
      type: type,
      node_id: node_id,
      command_ref: Keyword.get(opts, :command_ref, nil),
      transmission_stats: Keyword.get(opts, :transmission_stats, []),
      queued_delay: Keyword.get(opts, :queued_delay, 0),
      command: Keyword.get(opts, :command),
      queued: Keyword.get(opts, :queued, false),
      acknowledged: Keyword.get(opts, :acknowledged, false)
    }
  end

  @doc false
  @spec unsolicited(Grizzly.node_id(), Command.t(), [opt()]) :: t()
  def unsolicited(node_id, %Command{} = command, opts \\ []) do
    new(:complete, :unsolicited, node_id, Keyword.merge(opts, command: command))
  end

  @doc false
  @spec command(Grizzly.node_id(), Command.t(), [opt()]) :: t()
  def command(node_id, %Command{} = command, opts \\ []) do
    new(:complete, :command, node_id, Keyword.merge(opts, command: command))
  end
end
