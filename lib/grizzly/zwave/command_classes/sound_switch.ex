defmodule Grizzly.ZWave.CommandClasses.SoundSwitch do
  @moduledoc """
  The Sound Switch Command Class is used to manage nodes with a speaker or sound
  notification capability. It can be used for a doorbell, alarm clock, siren or
  any device issuing sound notifications.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @typedoc """
  The tone identifier at the receiving node.
  """
  @type tone_identifier :: 0..255

  @typedoc """
  The volume at which a tone is played.

  ## Values

  * `0` - Indicates an off/mute volume setting.
  * `1..100` - Indicates the actual volume setting from 1% to 100%.
  * `255` - Restore the most recent non-zero volume setting. This value MUST be
    ignored if the current volume is not zero. This value MAY be used to set the
    default tone without modifying the volume setting.
  """
  @type volume :: 0..100 | 255

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x79

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :sound_switch
end
