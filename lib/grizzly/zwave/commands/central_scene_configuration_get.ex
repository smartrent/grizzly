defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationGet do
  @moduledoc """
  This command is used to query the configuration of optional node capabilities for scene notifications

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene

  @impl true
  def new(params \\ []) do
    command = %Command{
      name: :central_scene_configuration_get,
      command_byte: 0x05,
      command_class: CentralScene,
      params: params,
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
