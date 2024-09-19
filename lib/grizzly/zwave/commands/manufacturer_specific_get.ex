defmodule Grizzly.ZWave.Commands.ManufacturerSpecificGet do
  @moduledoc """
  Module for the MANUFACTURER_SPECIFIC_GET command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ManufacturerSpecific

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :manufacturer_specific_get,
      command_byte: 0x04,
      command_class: ManufacturerSpecific,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
