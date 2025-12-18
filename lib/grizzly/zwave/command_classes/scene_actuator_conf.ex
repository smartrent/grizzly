defmodule Grizzly.ZWave.CommandClasses.SceneActuatorConf do
  @moduledoc """
  "SceneActuatorConf" Command Class

  The Scene Actuator Configuration Command Class is used to configure scenes settings for a node
  supporting an actuator Command Class, e.g. a multilevel switch, binary switch etc.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type dimming_duration :: :instantly | [seconds: 1..127] | [minutes: 1..127] | :factory_settings
  @type level :: :on | :off | 1..99

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x2C

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :scene_actuator_conf

  @spec dimming_duration_to_byte(dimming_duration) :: byte
  def dimming_duration_to_byte(:instantly), do: 0
  def dimming_duration_to_byte(:factory_settings), do: 255
  def dimming_duration_to_byte(seconds: seconds) when seconds in 1..127, do: seconds
  # 0x80..0xFE 1 minute (0x80) to 127 minutes (0xFE) in 1 minute resolution.
  def dimming_duration_to_byte(minutes: minutes) when minutes in 1..127, do: 0x7F + minutes

  @spec dimming_duration_from_byte(byte) ::
          {:ok, dimming_duration} | {:error, Grizzly.ZWave.DecodeError.t()}
  def dimming_duration_from_byte(0), do: {:ok, :instantly}
  def dimming_duration_from_byte(255), do: {:ok, :factory_settings}
  def dimming_duration_from_byte(byte) when byte in 1..127, do: {:ok, [seconds: byte]}
  def dimming_duration_from_byte(byte) when byte in 0x80..0xFE, do: {:ok, [minutes: byte - 0x7F]}

  def dimming_duration_from_byte(byte),
    do: {:error, %DecodeError{param: :dimming_duration, value: byte}}

  @spec level_to_byte(level) :: byte
  def level_to_byte(:on), do: 0xFF
  def level_to_byte(:off), do: 0x00
  def level_to_byte(byte) when byte in 1..99, do: byte

  @spec level_from_byte(byte) :: {:ok, level} | {:error, Grizzly.ZWave.DecodeError.t()}
  def level_from_byte(0), do: {:ok, :off}
  def level_from_byte(0xFF), do: {:ok, :on}
  def level_from_byte(byte) when byte in 1..99, do: {:ok, byte}
  def level_from_byte(byte), do: {:error, %DecodeError{param: :level, value: byte}}
end
