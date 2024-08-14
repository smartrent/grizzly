defmodule Grizzly.ZWave.Commands.TimeOffsetGet do
  @moduledoc """
  This command is used to request the Time Zone Offset (TZO) and Daylight Savings Time (DST)
   parameters from a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :time_offset_get,
      command_byte: 0x06,
      command_class: Time,
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
