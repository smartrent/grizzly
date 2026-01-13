defmodule Grizzly.ZWave.Commands.DoorLockOperationSet do
  @moduledoc """
  OperationSet command allows you to lock or unlock lock devices

  Params:

    * `:mode` - the mode of the operation of the lock device
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @type param :: {:mode, DoorLock.mode()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    mode = Command.param!(command, :mode)
    <<DoorLock.mode_to_byte(mode)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<mode_byte>>) do
    {:ok, [mode: DoorLock.mode_from_byte(mode_byte)]}
  end
end
