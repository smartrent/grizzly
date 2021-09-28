defmodule Grizzly.ZWave.Commands.BatteryGet do
  @moduledoc """
  This module implements the BATTERY_GET command in the COMMAND_CLASS_BATTERY
  command class.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Battery

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :battery_get,
      command_byte: 0x02,
      command_class: Battery,
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
