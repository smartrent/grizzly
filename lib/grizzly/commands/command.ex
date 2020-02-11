defmodule Grizzly.Commands.Command do
  @moduledoc false

  # Data structure for working with Z-Wave commands as they relate to the
  # Grizzly runtime
  alias Grizzly.SeqNumber
  alias Grizzly.ZWave.Command, as: ZWaveCommand
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type t :: %__MODULE__{
          owner: pid(),
          retries: non_neg_integer(),
          source: ZWaveCommand.t(),
          handler_state: any(),
          handler: module(),
          seq_number: Grizzly.seq_number(),
          timeout_ref: reference() | nil,
          ref: reference()
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
            ref: nil

  def from_zwave_command(zwave_command, owner, timeout_ref \\ nil, opts \\ []) do
    {handler, handler_init_args} = get_handler_spec(zwave_command)
    {:ok, handler_state} = handler.init(handler_init_args)
    retries = Keyword.get(opts, :retries, 2)
    command_ref = Keyword.get(opts, :reference, make_ref())

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
    command.source
    |> ZIPPacket.with_zwave_command(seq_number: command.seq_number)
    |> ZIPPacket.to_binary()
  end

  @spec handle_zip_packet(t(), ZIPPacket.t()) ::
          {:continue, t()}
          | {:error, :nack_response, t()}
          | {:queued, non_neg_integer(), t()}
          | {:complete, t()}
          | {:retry, t()}
  def handle_zip_packet(command, zip_packet) do
    case zip_packet.flag do
      :ack_response ->
        handle_ack_response(command, zip_packet)

      :nack_response ->
        handle_nack_response(command, zip_packet)

      :nack_waiting ->
        handle_nack_waiting(command, zip_packet)

      _ ->
        handle_command(command, zip_packet)
    end
  end

  defp handle_ack_response(command, zip_packet) do
    if command.seq_number == zip_packet.seq_number do
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
        result
    end
  end

  defp handle_nack_response(command, zip_packet) do
    if command.seq_number == zip_packet.seq_number do
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
    if command.seq_number == zip_packet.seq_number do
      # SDS13784 Network specification states that a default of 90 seconds
      # should be used if no expected delay is provided.
      {:queued, ZIPPacket.extension(zip_packet, :expected_delay, 90), command}
    else
      {:continue, command}
    end
  end

  defp handle_command(command, zip_packet) do
    case command.handler.handle_command(zip_packet.command, command.handler_state) do
      {:continue, new_handler_state} ->
        {:continue, %__MODULE__{command | handler_state: new_handler_state}}

      {:complete, _response} = result ->
        result
    end
  end

  defp get_handler_spec(zwave_command) do
    case zwave_command.handler do
      {_handler, _handler_init_args} = spec -> spec
      handler -> {handler, []}
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
end
