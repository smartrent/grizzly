defmodule Grizzly.ZWave.Commands.ManufacturerSpecificGet do
  @moduledoc """
  Module for the MANUFACTURER_SPECIFIC_GET command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
