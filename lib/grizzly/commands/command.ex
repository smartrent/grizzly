defmodule Grizzly.Commands.Command do
  @moduledoc false

  require Logger

  # Data structure for working with Z-Wave commands as they relate to the
  # Grizzly runtime
  alias Grizzly.CommandHandlers.SupervisionReport
  alias Grizzly.Commands.Table
  alias Grizzly.{Report, SeqNumber, ZWave}
  alias Grizzly.ZWave.Command, as: ZWaveCommand
  alias Grizzly.ZWave.Commands.{SupervisionGet, ZIPPacket}

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
          node_id: ZWave.node_id(),
          supervision?: boolean(),
          more_info?: boolean(),
          session_id: non_neg_integer() | nil,
          acknowledged: boolean()
        }

  @type opt ::
          {:timeout_ref, reference()}
          | {:reference, reference()}
          | {:retries, non_neg_integer()}
          | {:transmission_stats, boolean()}

  defstruct owner: nil,
            retries: 0,
            source: nil,
            handler_state: nil,
            handler: nil,
            seq_number: nil,
            timeout_ref: nil,
            ref: nil,
            status: :inflight,
            with_transmission_stats: false,
            transmission_stats: [],
            node_id: nil,
            supervision?: false,
            more_info?: false,
            session_id: nil,
            acknowledged: false

  @spec from_zwave_command(ZWaveCommand.t(), ZWave.node_id(), pid(), [opt()]) :: t()
  def from_zwave_command(zwave_command, node_id, owner, opts \\ []) do
    retries = Keyword.get(opts, :retries, 0)
    command_ref = Keyword.get(opts, :reference, make_ref())
    timeout_ref = Keyword.get(opts, :timeout_ref)
    with_transmission_stats = Keyword.get(opts, :transmission_stats, false)
    more_info = Keyword.get(opts, :more_info, false)

    {zwave_command, handler, handler_init_args, supervision?, session_id} =
      if use_supervision?(zwave_command, opts) do
        zwave_command = add_supervision_encapsulation(zwave_command, node_id, opts)
        session_id = ZWaveCommand.param!(zwave_command, :session_id)

        handler_init_args = [
          session_id: session_id,
          node_id: node_id,
          command_ref: command_ref,
          waiter: Keyword.get(opts, :waiter),
          status_updates?: Keyword.get(opts, :status_updates?, false)
        ]

        {zwave_command, SupervisionReport, handler_init_args, true, session_id}
      else
        _ = maybe_warn_supervision(zwave_command, opts[:supervision?])
        {handler, handler_init_args} = get_handler_spec(zwave_command, opts)
        {zwave_command, handler, handler_init_args, false, nil}
      end

    {:ok, handler_state} = handler.init(zwave_command, handler_init_args)

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
      node_id: node_id,
      supervision?: supervision?,
      session_id: session_id,
      more_info?: more_info
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
          | {:retry, t()}
          | {:continue, t()}
  def handle_zip_command(command, zip_command) do
    case ZWaveCommand.param!(zip_command, :flag) do
      :ack_response ->
        handle_ack_response(command, zip_command)

      :nack_waiting ->
        handle_nack_waiting(command, zip_command)

      flag when flag in [:nack_response, :nack_queue_full] ->
        handle_final_nack(command, zip_command)

      flag when flag in [nil, :ack_request] ->
        do_handle_zip_command(command, zip_command)
    end
  end

  defp handle_ack_response(command, zip_packet) do
    seq_number = ZWaveCommand.param!(zip_packet, :seq_number)

    if command.seq_number == seq_number do
      do_handle_ack_response(%__MODULE__{command | acknowledged: true}, zip_packet)
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

  # Handles both nack response and nack queue full
  defp handle_final_nack(command, zip_packet) do
    flag = ZWaveCommand.param!(zip_packet, :flag)
    seq_number = ZWaveCommand.param!(zip_packet, :seq_number)

    cond do
      command.seq_number != seq_number ->
        {:continue, command}

      # Never retry on a nack_queue_full
      flag == :nack_queue_full ->
        make_queue_full_response(command)

      command.retries > 0 ->
        {:retry, %__MODULE__{command | retries: command.retries - 1}}

      true ->
        make_nack_response(command)
    end
  end

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
        Table.handler(zwave_command.name)

      handler ->
        Table.format_handler_spec(handler)
    end
  end

  defp maybe_warn_supervision(command, true) do
    Logger.warning(
      "[Grizzly] Supervision was requested for command #{command.name} but is not supported"
    )
  end

  defp maybe_warn_supervision(_, _), do: :ok

  defp use_supervision?(zwave_command, opts) do
    opts[:supervision?] == true && Table.supports_supervision?(zwave_command.name)
  end

  defp add_supervision_encapsulation(zwave_command, node_id, opts) do
    if Keyword.get(opts, :supervision?) do
      encapsulated_command = ZWaveCommand.to_binary(zwave_command)

      {:ok, command} =
        SupervisionGet.new(
          status_updates: :one_now_more_later,
          session_id: Grizzly.SessionId.get_and_inc(node_id),
          encapsulated_command: encapsulated_command
        )

      command
    else
      zwave_command
    end
  end

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

  defp make_nack_response(command) do
    {Report.new(:complete, :nack_response, command.node_id,
       command_ref: command.ref,
       queued: command.status == :queued,
       transmission_stats: command.transmission_stats
     ), %__MODULE__{command | status: :complete}}
  end

  defp make_queue_full_response(command) do
    {Report.new(:complete, :queue_full, command.node_id,
       command_ref: command.ref,
       queued: command.status == :queued,
       transmission_stats: command.transmission_stats
     ), %__MODULE__{command | status: :complete}}
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
               acknowledged: true,
               queued: true,
               transmission_stats: command.transmission_stats
             ), %__MODULE__{command | status: :complete}}

          %ZWaveCommand{} ->
            {Report.new(:complete, :command, command.node_id,
               command_ref: command.ref,
               acknowledged: command.acknowledged,
               command: response,
               queued: true,
               transmission_stats: command.transmission_stats
             ), %__MODULE__{command | status: :complete}}
        end
    end
  end

  defp make_zip_packet_command_opts(grizzly_command) do
    Keyword.new()
    |> maybe_add_installation_and_maintenance_get(grizzly_command)
    |> maybe_add_more_info_flag(grizzly_command)
    |> add_seq_number(grizzly_command)
  end

  defp maybe_add_installation_and_maintenance_get(opts, grizzly_command) do
    if grizzly_command.with_transmission_stats do
      Keyword.put(opts, :header_extensions, [:installation_and_maintenance_get])
    else
      opts
    end
  end

  defp maybe_add_more_info_flag(opts, grizzly_command) do
    if grizzly_command.more_info? do
      Keyword.put(opts, :more_info, true)
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
        {:last_working_route, routes, speed}, m ->
          Keyword.put(m, :last_working_route, routes) |> Keyword.put(:transmission_speed, speed)

        # These values will only be available when the destination node is an LR node
        {local_power_field, value, remote_power_field, remote_value}, meta
        when local_power_field in [:local_node_tx_power, :local_noise_floor] ->
          meta =
            if value != :not_available do
              Keyword.put(meta, local_power_field, value)
            else
              meta
            end

          if remote_value != :not_available do
            Keyword.put(meta, remote_power_field, remote_value)
          else
            meta
          end

        # This value will only be available when the destination node is an LR node
        {:outgoing_rssi_hops, hops}, meta ->
          if is_integer(Enum.at(hops, 0)) do
            Keyword.put(meta, :outgoing_rssi_hops, hops)
          else
            meta
          end

        {key, value}, m ->
          Keyword.put(m, key, value)
      end)
      |> calculate_rssi_values()
    else
      meta
    end
  end

  defp calculate_rssi_values(stats) do
    min_rssi =
      Keyword.get(stats, :rssi_hops, [])
      |> Enum.filter(&is_number/1)
      |> Enum.min(fn -> :not_available end)

    Keyword.put(stats, :rssi_dbm, min_rssi)
    |> Keyword.put(:rssi_4bars, calculate_bars(min_rssi))
  end

  # These values were determined based on -78dBm being the lowest RSSI considered
  # to be 4 bars, and -97 being the lowest value for 1 bar. The thresholds for
  # 2 and 3 bars were calculated using a logarithmic regression model represented
  # in the following R script:
  #
  #     rssi <- c(-78, -97)
  #     bars <- c(4, 1)
  #     model <- lm(bars ~ log(abs(rssi), 2))
  #     coeffs <- coef(model)
  #     a <- coeffs[1]
  #     b <- coeffs[2]
  #     bars_to_rssi <- function(bars) round((2 ^ ((bars - a) / b)) * -1)
  #     cat("1 bar  >=", bars_to_rssi(1), "dBm\n")
  #     cat("2 bars >=", bars_to_rssi(2), "dBm\n")
  #     cat("3 bars >=", bars_to_rssi(3), "dBm\n")
  #     cat("4 bars >=", bars_to_rssi(4), "dBm\n")
  defp calculate_bars(:not_available), do: :not_available
  defp calculate_bars(rssi) when rssi >= -78, do: 4
  defp calculate_bars(rssi) when rssi >= -84, do: 3
  defp calculate_bars(rssi) when rssi >= -90, do: 2
  defp calculate_bars(rssi) when rssi >= -97, do: 1
  defp calculate_bars(_rssi), do: 0

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
      node_id: command.node_id,
      acknowledged: command.acknowledged
    }
  end

  defp build_report(command, response) do
    %Report{
      status: :complete,
      command: response,
      transmission_stats: command.transmission_stats,
      type: :command,
      command_ref: command.ref,
      node_id: command.node_id,
      acknowledged: command.acknowledged
    }
  end
end
