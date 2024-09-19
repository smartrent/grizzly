defmodule Grizzly.ZWave.Commands.DoorLockCapabilitiesGet do
  @moduledoc """
  This command is used to request the Door Lock capabilities of a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :door_lock_capabilities_get,
      command_byte: 0x07,
      command_class: DoorLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
