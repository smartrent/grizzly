defmodule Grizzly.ZWave.Commands.DoorLockConfigurationGet do
  @moduledoc """
  This command is used to request the configuration parameters of a door lock device.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @impl true
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

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
