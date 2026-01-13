defmodule Grizzly.ZWave.Commands.SceneActuatorConfGet do
  @moduledoc """
  This command is used to request the settings for a given scene identifier or for the scene currently active.

  Params:

    * `:scene_id` - a scene id, 0 for the currently active scene, if any (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:scene_id, 0..255}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    scene_id = Command.param!(command, :scene_id)
    <<scene_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<scene_id>>) do
    {:ok, [scene_id: scene_id]}
  end
end
