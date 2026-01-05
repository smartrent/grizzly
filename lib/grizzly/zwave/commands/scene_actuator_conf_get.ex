defmodule Grizzly.ZWave.Commands.SceneActuatorConfGet do
  @moduledoc """
  This command is used to request the settings for a given scene identifier or for the scene currently active.

  Params:

    * `:scene_id` - a scene id, 0 for the currently active scene, if any (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SceneActuatorConf
  alias Grizzly.ZWave.DecodeError

  @type param :: {:scene_id, 0..255}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :scene_actuator_conf_get,
      command_byte: 0x02,
      command_class: SceneActuatorConf,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    scene_id = Command.param!(command, :scene_id)
    <<scene_id>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<scene_id>>) do
    {:ok, [scene_id: scene_id]}
  end
end
