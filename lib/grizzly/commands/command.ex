defmodule Grizzly.Commands.Command do
  @moduledoc false

  # Data structure for working with Z-Wave commands as they relate to the
  # Grizzly runtime
  alias Grizzly.{Report, SeqNumber, ZWave}
  alias Grizzly.Commands.Table
  alias Grizzly.ZWave.Command, as: ZWaveCommand
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type status :: :inflight | :queued | :complete

  @type t :: %__MODULE__{
          owner: pid(),
          retries: non_neg_integer(),
          source: ZWaveCommand.t(),
          handler_state: any(),
          handler: module(),
          seq_number: Grizzly.seq_number(),
          timeout_ref: reference() | nil,
          ref: reference(),
          status: status(),
          with_transmission_stats: boolean(),
          transmission_stats: keyword(),
          node_id: ZWave.node_id()
        }

  @type opt ::
          {:timeout_ref, reference()}
          | {:reference, reference()}
          | {:retries, non_neg_integer()}
          | {:transmission_stats, boolean()}

  defstruct owner: nil,
            retries: 2,
            source: nil,
            handler_state: nil,
            handler: nil,
            seq_number: nil,
            timeout_ref: nil,
            ref: nil,
            status: :inflight,
            with_transmission_stats: false,
            transmission_stats: [],
            node_id: nil

  @spec from_zwave_command(ZWaveCommand.t(), ZWave.node_id(), pid(), [opt()]) :: t()
  def from_zwave_command(zwave_command, node_id, owner, opts \\ []) do
    {handler, handler_init_args} = get_handler_spec(zwave_command, opts)
    {:ok, handler_state} = handler.init(handler_init_args)
    retries = Keyword.get(opts, :retries, 2)
    command_ref = Keyword.get(opts, :reference, make_ref())
    timeout_ref = Keyword.get(opts, :timeout_ref)
    with_transmission_stats = Keyword.get(opts, :transmission_stats, false)

    %__MODULE__{
      handler: handler,
      handler_state: handler_state,
      source: zwave_command,
      owner: owner,
      seq_number: get_seq_number(zwave_command),
      timeout_ref: timeout_ref,
      retries: retries,
      ref: command_ref,
      with_transmission_stats: with_transmission_stats,
      node_id: node_id
    }
  end

  @spec to_binary(t()) :: binary()
  def to_binary(command) do
    zwave_command = command.source

    case zwave_command.name do
      :keep_alive ->
        <<zwave_command.command_class.byte(), zwave_command.command_byte>> <>
          ZWaveCommand.encode_params(zwave_command)

      _other ->
        opts = make_zip_packet_command_opts(command)

        {:ok, zip_packet_command} =
          ZIPPacket.with_zwave_command(zwave_command, command.seq_number, opts)

        ZWaveCommand.to_binary(zip_packet_command)
    end
  end

  @spec handle_zip_command(t(), ZWaveCommand.t()) ::
          {Report.t(), t()}
          | {:error, :nack_response, t()}
          | {:retry, t()}
          | {:continue, t()}
  def handle_zip_command(command, zip_command) do
    case ZWaveCommand.param!(zip_command, :flag) do
      :ack_response ->
        handle_ack_response(command, zip_command)

      :nack_response ->
        handle_nack_response(command, zip_command)

      :nack_waiting ->
        handle_nack_waiting(command, zip_command)

      flag when flag in [nil, :ack_request] ->
        do_handle_zip_command(command, zip_command)
    end
  end

  defp handle_ack_response(command, zip_packet) do
    seq_number = ZWaveCommand.param!(zip_packet, :seq_number)

    if command.seq_number == seq_number do
      do_handle_ack_response(command, zip_packet)
    else
      {:continue, command}
    end
  end

  defp do_handle_ack_response(command, zip_packet) do
    transmission_stats = make_network_stats(command, zip_packet)

    case command.handler.handle_ack(command.handler_state) do
      {:continue, new_handler_state} ->
        {:continue,
         %__MODULE__{
           command
           | handler_state: new_handler_state,
             transmission_stats: transmission_stats
         }}

      {:complete, response} ->
        build_complete_reply(
          %__MODULE__{command | transmission_stats: transmission_stats},
          response
        )
    end
  end

  defp handle_nack_response(command, zip_packet) do
    seq_number = ZWaveCommand.param!(zip_packet, :seq_number)

    if command.seq_number == seq_number do
      handle_nack_response(command)
    else
      {:continue, command}
    end
  end

  defp handle_nack_response(%__MODULE__{retries: 0} = command),
    do: {:error, :nack_response, command}

  defp handle_nack_response(%__MODULE__{retries: n} = command),
    do: {:retry, %__MODULE__{command | retries: n - 1}}

  defp handle_nack_waiting(command, zip_packet) do
    seq_number = ZWaveCommand.param!(zip_packet, :seq_number)

    if command.seq_number == seq_number do
      # SDS13784 Network specification states that a default of 90 seconds
      # should be used if no expected delay is provided.
      make_queued_response(command, zip_packet)
    else
      {:continue, command}
    end
  end

  defp do_handle_zip_command(command, zip_packet_command) do
    zwave_command = ZWaveCommand.param!(zip_packet_command, :command)

    case command.handler.handle_command(zwave_command, command.handler_state) do
      {:continue, new_handler_state} ->
        {:continue, %__MODULE__{command | handler_state: new_handler_state}}

      {:complete, response} ->
        build_complete_reply(command, response)
    end
  end

  defp get_handler_spec(zwave_command, opts) do
    case Keyword.get(opts, :handler) do
      nil ->
        format_handler_spec(Table.handler(zwave_command.name))

      handler ->
        format_handler_spec(handler)
    end
  end

  defp format_handler_spec({_handler, _args} = spec), do: spec
  defp format_handler_spec(handler), do: {handler, []}

  defp get_seq_number(zwave_command) do
    case ZWaveCommand.param(zwave_command, :seq_number) do
      nil ->
        SeqNumber.get_and_inc()

      seq_number ->
        seq_number
    end
  end

  defp make_queued_response(command, zip_packet) do
    case ZIPPacket.extension(zip_packet, :expected_delay, 90) do
      delay when delay > 1 ->
        make_queued_or_queued_ping_response(command, delay)

      _other ->
        {:continue, command}
    end
  end

  defp make_queued_or_queued_ping_response(command, delay) do
    case command.status do
      :inflight ->
        queued_delay_report =
          Report.new(:inflight, :queued_delay, command.node_id,
            command_ref: command.ref,
            queued_delay: delay,
            queued: true
          )

        {queued_delay_report, %__MODULE__{command | status: :queued}}

      :queued ->
        {Report.new(:inflight, :queued_ping, command.node_id,
           command_ref: command.ref,
           queued_delay: delay,
           queued: true
         ), command}
    end
  end

  defp build_complete_reply(command, response) do
    case command.status do
      :inflight ->
        {build_report(command, response), %__MODULE__{command | status: :complete}}

      :queued ->
        case response do
          :ok ->
            {Report.new(:complete, :ack_response, command.node_id,
               command_ref: command.ref,
               queued: true
             ), %__MODULE__{command | status: :complete}}

          %ZWaveCommand{} ->
            {Report.new(:complete, :command, command.node_id,
               command_ref: command.ref,
               command: response,
               queued: true
             ), %__MODULE__{command | status: :complete}}
        end
    end
  end

  defp make_zip_packet_command_opts(grizzly_command) do
    Keyword.new()
    |> maybe_add_installation_and_maintenance_get(grizzly_command)
    |> add_seq_number(grizzly_command)
  end

  defp maybe_add_installation_and_maintenance_get(opts, grizzly_command) do
    if grizzly_command.with_transmission_stats do
      Keyword.put(opts, :header_extensions, [:install_and_maintenance_get])
    else
      opts
    end
  end

  defp add_seq_number(opts, grizzly_command) do
    Keyword.put(opts, :seq_number, grizzly_command.seq_number)
  end

  defp make_network_stats(command, zip_packet) do
    Keyword.new()
    |> maybe_return_network_stats(command, zip_packet)
  end

  defp maybe_return_network_stats(meta, command, zip_packet) do
    if command.with_transmission_stats do
      stats = get_stats_from_zip_packet(zip_packet)

      Enum.reduce(stats, meta, fn
        {key, value}, m -> Keyword.put(m, key, value)
        {key, value, value2}, m -> Keyword.put(m, key, {value, value2})
      end)
    else
      meta
    end
  end

  defp get_stats_from_zip_packet(zip_packet) do
    case ZIPPacket.extension(zip_packet, :installation_and_maintenance_report) do
      nil ->
        []

      report ->
        report
    end
  end

  defp build_report(command, :ok) do
    %Report{
      status: :complete,
      command_ref: command.ref,
      transmission_stats: command.transmission_stats,
      type: :ack_response,
      node_id: command.node_id
    }
  end

  defp build_report(command, response) do
    %Report{
      status: :complete,
      command: response,
      transmission_stats: command.transmission_stats,
      type: :command,
      command_ref: command.ref,
      node_id: command.node_id
    }
  end
end
