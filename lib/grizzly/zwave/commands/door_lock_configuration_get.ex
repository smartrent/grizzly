defmodule Grizzly.ZWave.Commands.DoorLockConfigurationGet do
  @moduledoc """
  This command is used to request the configuration parameters of a door lock device.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :door_lock_configuration_get,
      command_byte: 0x05,
      command_class: DoorLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
