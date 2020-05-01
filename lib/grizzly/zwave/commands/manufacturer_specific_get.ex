defmodule Grizzly.ZWave.Commands.ManufacturerSpecificGet do
  @moduledoc """
  Module for the MANUFACTURER_SPECIFIC_GET command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ManufacturerSpecific

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :manufacturer_specific_get,
      command_byte: 0x04,
      command_class: ManufacturerSpecific,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def decode_params(_), do: {:ok, []}

  @impl true
  def encode_params(_), do: <<>>
end
