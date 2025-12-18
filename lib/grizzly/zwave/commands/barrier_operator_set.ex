defmodule Grizzly.ZWave.Commands.BarrierOperatorSet do
  @moduledoc """
  This command is used to initiate an unattended change in state of the barrier.

  Params:

    * `:target_value` - explain what `:target_value` param is for

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.BarrierOperator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:target_value, BarrierOperator.target_value()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :barrier_operator_set,
      command_byte: 0x01,
      command_class: BarrierOperator,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    target_value = Command.param!(command, :target_value)
    target_value_byte = BarrierOperator.target_value_to_byte(target_value)
    <<target_value_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<target_value_byte>>) do
    case BarrierOperator.target_value_from_byte(target_value_byte) do
      {:ok, target_value} ->
        {:ok, [target_value: target_value]}

      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :barrier_operator_set}}
    end
  end
end
