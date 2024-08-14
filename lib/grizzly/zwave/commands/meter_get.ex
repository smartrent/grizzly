defmodule Grizzly.ZWave.Commands.MeterGet do
  @moduledoc """
  This module implements the METER_GET command of the COMMAND_CLASS_METER command class.

  This command is used to request the current meter reading to a supporting node.

  Params: - none - (v1)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Meter

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :meter_get,
      command_byte: 0x01,
      command_class: Meter,
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
