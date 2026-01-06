defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalReport do
  @moduledoc """
  This command is used to indicate the state of a notification subsystem of a Barrier Device.

  Params:

    * `:subsystem_type` - This field is used to indicate which type of subsystem

    * `:subsystem_state` - This field is used to indicate the state that the specified subsystem MUST assume at the receiving node

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.BarrierOperator
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:subsystem_type, BarrierOperator.subsystem_type()}
          | {:subsystem_state, BarrierOperator.subsystem_state()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :barrier_operator_signal_report,
      command_byte: 0x08,
      command_class: BarrierOperator,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    subsystem_type = Command.param!(command, :subsystem_type)
    subsystem_type_byte = BarrierOperator.subsystem_type_to_byte(subsystem_type)
    subsystem_state = Command.param!(command, :subsystem_state)
    subsystem_state_byte = BarrierOperator.subsystem_state_to_byte(subsystem_state)

    <<subsystem_type_byte, subsystem_state_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<subsystem_type_byte, subsystem_state_byte>>) do
    with {:ok, subsystem_type} <- BarrierOperator.subsystem_type_from_byte(subsystem_type_byte),
         {:ok, subsystem_state} <- BarrierOperator.subsystem_state_from_byte(subsystem_state_byte) do
      {:ok, [subsystem_type: subsystem_type, subsystem_state: subsystem_state]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :barrier_operator_signal_report}}
    end
  end
end
