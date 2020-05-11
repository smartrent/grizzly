defmodule Grizzly.Commands.Command do
  @moduledoc false

  # Data structure for working with Z-Wave commands as they relate to the
  # Grizzly runtime
  alias Grizzly.SeqNumber
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
          status: status()
        }

  @type opt ::
          {:timeout_ref, reference()} | {:reference, reference()} | {:retries, non_neg_integer()}

  defstruct owner: nil,
            retries: 2,
            source: nil,
            handler_state: nil,
            handler: nil,
            seq_number: nil,
            timeout_ref: nil,
            ref: nil,
            status: :inflight

  def from_zwave_command(zwave_command, owner, opts \\ []) do
    {handler, handler_init_args} = get_handler_spec(zwave_command, opts)
    {:ok, handler_state} = handler.init(handler_init_args)
    retries = Keyword.get(opts, :retries, 2)
    command_ref = Keyword.get(opts, :reference, make_ref())
    timeout_ref = Keyword.get(opts, :timeout_ref)

    %__MODULE__{
      handler: handler,
      handler_state: handler_state,
      source: zwave_command,
      owner: owner,
      seq_number: get_seq_number(zwave_command),
      timeout_ref: timeout_ref,
      retries: retries,
      ref: command_ref
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
        {:ok, zip_packet_command} =
          ZIPPacket.with_zwave_command(zwave_command, command.seq_number,
            seq_number: command.seq_number
          )

        ZWaveCommand.to_binary(zip_packet_command)
    end
  end

  @spec handle_zip_command(t(), ZWaveCommand.t()) ::
          {:continue, t()}
          | {:error, :nack_response, t()}
          | {:queued_complete, any(), t()}
          | {:queued_ping, non_neg_integer(), t()}
          | {:queued, non_neg_integer(), t()}
          | {:complete, any(), t()}
          | {:retry, t()}
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
      handle_ack_response(command)
    else
      {:continue, command}
    end
  end

  defp handle_ack_response(command) do
    case command.handler.handle_ack(command.handler_state) do
      {:continue, new_handler_state} ->
        {:continue, %__MODULE__{command | handler_state: new_handler_state}}

      {:complete, _response} = result ->
        build_complete_reply(command, result)
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

      {:complete, _response} = result ->
        build_complete_reply(command, result)
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
        {:queued, delay, %__MODULE__{command | status: :queued}}

      :queued ->
        {:queued_ping, delay, command}
    end
  end

  defp build_complete_reply(command, {:complete, result}) do
    case command.status do
      :inflight ->
        {:complete, result, %__MODULE__{command | status: :complete}}

      :queued ->
        {:queued_complete, format_result(result), %__MODULE__{command | status: :complete}}
    end
  end

  defp format_result({:ok, command}), do: command
  defp format_result(:ok), do: :ok
end
