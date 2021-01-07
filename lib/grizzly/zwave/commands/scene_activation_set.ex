defmodule Grizzly.ZWave.Commands.SceneActivationSet do
  @moduledoc """
  What does this command do??

  Params:

    * `:scene_id` -  a scene id (required)

    * `:dimming_duration` - the time that the transition from the current level to the target level (required - ignored if not applicable to target device)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.{SceneActivation, SceneActuatorConf}

  @type param ::
          {:scene_id, boolean}
          | {:dimming_duration, SceneActuatorConf.dimming_duration()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :scene_activation_set,
      command_byte: 0x01,
      command_class: SceneActivation,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    scene_id = Command.param!(command, :scene_id)

    dimming_duration_byte =
      Command.param!(command, :dimming_duration) |> SceneActuatorConf.dimming_duration_to_byte()

    <<scene_id, dimming_duration_byte>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<scene_id, dimming_duration_byte>>) do
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
