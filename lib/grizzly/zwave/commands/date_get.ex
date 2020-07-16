defmodule Grizzly.ZWave.Commands.DateGet do
  @moduledoc """
  This command is used to request the current date adjusted according to the local time zone and
  Daylight Saving Time from a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :date_get,
      command_byte: 0x03,
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
