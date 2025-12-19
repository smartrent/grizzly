defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalGet do
  @moduledoc """
  This command is used to request the state of a signaling subsystem to a supporting node.

  Params:

    * `:subsystem_type` - This field is used to indicate which type of subsystem
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.BarrierOperator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:subsystem_type, BarrierOperator.subsystem_type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :barrier_operator_signal_get,
      command_byte: 0x07,
      command_class: BarrierOperator,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    subsystem_type = Command.param!(command, :subsystem_type)
    byte = BarrierOperator.subsystem_type_to_byte(subsystem_type)
    <<byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<subsystem_byte>>) do
    case BarrierOperator.subsystem_type_from_byte(subsystem_byte) do
      {:error, %DecodeError{} = decode_error} ->
        {:error,
         %DecodeError{
           decode_error
           | command: :barrier_operator_signal_get
         }}

      {:ok, subsystem_type} ->
        {:ok, [subsystem_type: subsystem_type]}
    end
  end
end
