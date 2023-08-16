defmodule Grizzly.ZWave.Commands.DoorLockOperationSet do
  @moduledoc """
  OperationSet command allows you to lock or unlock lock devices

  Params:

    * `:mode` - the mode of the operation of the lock device
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @type param :: {:mode, DoorLock.mode()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :door_lock_operation_set,
      command_byte: 0x01,
      command_class: DoorLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mode = Command.param!(command, :mode)
    <<DoorLock.mode_to_byte(mode)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<mode_byte>>) do
    {:ok, [mode: DoorLock.mode_from_byte(mode_byte)]}
  end
end
