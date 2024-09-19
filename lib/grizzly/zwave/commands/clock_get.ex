defmodule Grizzly.ZWave.Commands.ClockGet do
  @moduledoc """
  This command is used to request the current time set at a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Clock

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :clock_get,
      command_byte: 0x05,
      command_class: Clock,
      params: params,
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
