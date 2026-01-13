defmodule Grizzly.ZWave.Commands.BarrierOperatorReport do
  @moduledoc """
  This command is used to advertise the status of the barrier operator device.

  Params:

    * `:state` - The current state of the device

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.BarrierOperator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:state, BarrierOperator.state()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    state = Command.param!(command, :state)
    state_byte = BarrierOperator.state_to_byte(state)
    <<state_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<state_byte>>) do
    case BarrierOperator.state_from_byte(state_byte) do
      {:ok, state} ->
        {:ok, [state: state]}

      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :barrier_operator_report}}
    end
  end
end
