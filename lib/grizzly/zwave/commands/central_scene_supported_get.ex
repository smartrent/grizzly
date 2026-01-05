defmodule Grizzly.ZWave.Commands.CentralSceneSupportedGet do
  @moduledoc """
  This command is used to request the maximum number of scenes that this device supports.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :central_scene_supported_get,
      command_byte: 0x01,
      command_class: CentralScene,
      params: params
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
