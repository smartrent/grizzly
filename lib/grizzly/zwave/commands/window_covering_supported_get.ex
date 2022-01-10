defmodule Grizzly.ZWave.Commands.WindowCoveringSupportedGet do
  @moduledoc """
  This command is used to request the supported properties of a windows covering device.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WindowCovering

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :window_covering_supported_get,
      command_byte: 0x01,
      command_class: WindowCovering,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
