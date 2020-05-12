defmodule Grizzly.ZWave.Commands.MeterGet do
  @moduledoc """
  This module implements the METER_GET command of the COMMAND_CLASS_METER command class.

  This command is used to request the current meter reading to a supporting node.

  Params: - none - (v1)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Meter

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :meter_get,
      command_byte: 0x01,
      command_class: Meter,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
