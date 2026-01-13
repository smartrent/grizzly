defmodule Grizzly.ZWave.Commands.SceneActivationSet do
  @moduledoc """
  What does this command do??

  Params:

    * `:scene_id` -  a scene id (required)

    * `:dimming_duration` - the time that the transition from the current level to the target level (required - ignored if not applicable to target device)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SceneActuatorConf
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:scene_id, boolean}
          | {:dimming_duration, SceneActuatorConf.dimming_duration()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    scene_id = Command.param!(command, :scene_id)

    dimming_duration_byte =
      Command.param!(command, :dimming_duration) |> SceneActuatorConf.dimming_duration_to_byte()

    <<scene_id, dimming_duration_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<scene_id, dimming_duration_byte>>) do
    with {:ok, dimming_duration} <-
           SceneActuatorConf.dimming_duration_from_byte(dimming_duration_byte) do
      {:ok,
       [
         scene_id: scene_id,
         dimming_duration: dimming_duration
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :scene_activation_set}}
    end
  end
end
