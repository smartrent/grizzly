defmodule Grizzly.ZWave.Commands.TimeOffsetGet do
  @moduledoc """
  This command is used to request the Time Zone Offset (TZO) and Daylight Savings Time (DST)
   parameters from a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :time_offset_get,
      command_byte: 0x06,
      command_class: Time,
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
