defmodule Grizzly.ZWave.Commands.SceneActuatorConfSet do
  @moduledoc """
  This command is used to associate the specified scene ID to the defined actuator settings.

  Params:

    * `:scene_id` - a scene id (required)

    * `:dimming_duration` - the time it must take to reach the target level associated to the actual Scene ID (required - ignored if not supported)
                            :instantly | [seconds: 1..127] | [minutes: 1..126] | :factory_settings

    * `:override` - If false, the current actuator settings must be used as settings for the actual Scene ID (required)

    * `:level` - the target level to be set if override is true (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SceneActuatorConf
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:scene_id, boolean}
          | {:dimming_duration, SceneActuatorConf.dimming_duration()}
          | {:override, boolean}
          | {:level, SceneActuatorConf.level()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :scene_actuator_conf_set,
      command_byte: 0x01,
      command_class: SceneActuatorConf,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    scene_id = Command.param!(command, :scene_id)

    dimming_duration_byte =
      Command.param!(command, :dimming_duration) |> SceneActuatorConf.dimming_duration_to_byte()

    override_bit = if Command.param!(command, :override) == true, do: 1, else: 0
    level_byte = Command.param!(command, :level) |> SceneActuatorConf.level_to_byte()
    <<scene_id, dimming_duration_byte, override_bit::1, 0x00::7, level_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<scene_id, dimming_duration_byte, override_bit::1, _reserved::7, level_byte>>
      ) do
    with {:ok, dimming_duration} <-
           SceneActuatorConf.dimming_duration_from_byte(dimming_duration_byte),
         {:ok, level} <- SceneActuatorConf.level_from_byte(level_byte) do
      {:ok,
       [
         scene_id: scene_id,
         dimming_duration: dimming_duration,
         override: override_bit == 1,
         level: level
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :scene_actuator_conf_set}}
    end
  end
end
