defmodule Grizzly.ZWave.Commands.TimeGet do
  @moduledoc """
  This command is used to request the current time from a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :time_get,
      command_byte: 0x01,
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
