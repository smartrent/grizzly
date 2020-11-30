defmodule Grizzly.ZWave.CommandClasses.Indicator do
  @moduledoc """
  "Indicator" Command Class

  The Indicator Command Class is used to help end users to monitor the operation or condition of the
  application provided by a supporting node.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type value :: byte | :on | :off | :restore
  @type resource :: [indicator_id: indicator_id, property_id: property_id, value: byte]
  @type indicator_id ::
          byte
          | :armed
          | :disarmed
          | :ready
          | :fault
          | :busy
          | :enter_id
          | :enter_pin
          | :code_accepted
          | :armed_stay
          | :armed_away
          | :alarming
          | :alarming_burglar
          | :alarming_smoke_fire
          | :alarming_co
          | :bypass_challenger
          | :entry_delay
          | :alarming_medical
          | :alarming_freeze_warning
          | :alarming_water_leak
          | :alarming_panic
          | :zone_1_armed
          | :zone_2_armed
          | :zone_3_armed
          | :zone_4_armed
          | :zone_5_armed
          | :zone_6_armed
          | :zone_7_armed
          | :zone_8_armed
          | :lcd_backlight
          | :button_1
          | :button_2
          | :button_3
          | :button_4
          | :button_5
          | :button_6
          | :button_7
          | :button_8
          | :button_9
          | :button_10
          | :button_11
          | :button_12
          | :node_identify
          | :sound_1
          | :sound_2
          | :sound_3
          | :sound_4
          | :sound_5
          | :sound_6
          | :sound_7
          | :sound_8
          | :sound_9
          | :sound_10
          | :sound_11
          | :sound_12
          | :sound_13
          | :sound_14
          | :sound_15
          | :sound_16
          | :sound_17
          | :sound_18
          | :sound_19
          | :sound_20
          | :sound_21
          | :sound_22
          | :sound_23
          | :sound_24
          | :sound_25
          | :sound_26
          | :sound_27
          | :sound_28
          | :sound_29
          | :sound_30
          | :sound_31
          | :sound_32
          | :undefined

  @type property_id ::
          byte
          | :multilevel
          | :binary
          | :toggling_periods
          | :toggling_cycles
          | :toggling_on_time
          | :timeout_minutes
          | :timeout_seconds
          | :timeout_hundredths_second
          | :sound_level
          | :low_power
          | :undefined

  @impl true
  def byte(), do: 0x87

  @impl true
  def name(), do: :indicator

  def indicator_id_to_byte(:undefined), do: 0x00
  def indicator_id_to_byte(:armed), do: 0x01
  def indicator_id_to_byte(:disarmed), do: 0x02
  def indicator_id_to_byte(:ready), do: 0x03
  def indicator_id_to_byte(:fault), do: 0x04
  def indicator_id_to_byte(:busy), do: 0x05
  def indicator_id_to_byte(:enter_id), do: 0x06
  def indicator_id_to_byte(:enter_pin), do: 0x07
  def indicator_id_to_byte(:code_accepted), do: 0x08
  def indicator_id_to_byte(:code_not_accepted), do: 0x09
  def indicator_id_to_byte(:armed_stay), do: 0x0A
  def indicator_id_to_byte(:armed_away), do: 0x0B
  def indicator_id_to_byte(:alarming), do: 0x0C
  def indicator_id_to_byte(:alarming_burglar), do: 0x0D
  def indicator_id_to_byte(:alarming_smoke_fire), do: 0x0E
  def indicator_id_to_byte(:alarming_co), do: 0x0F
  def indicator_id_to_byte(:bypass_challenge), do: 0x10
  def indicator_id_to_byte(:entry_delay), do: 0x11
  def indicator_id_to_byte(:exit_delay), do: 0x12
  def indicator_id_to_byte(:alarming_medical), do: 0x13
  def indicator_id_to_byte(:alarming_freeze_warning), do: 0x14
  def indicator_id_to_byte(:alarming_water_leak), do: 0x15
  def indicator_id_to_byte(:alarming_panic), do: 0x16
  def indicator_id_to_byte(:zone_1_armed), do: 0x20
  def indicator_id_to_byte(:zone_2_armed), do: 0x21
  def indicator_id_to_byte(:zone_3_armed), do: 0x22
  def indicator_id_to_byte(:zone_4_armed), do: 0x23
  def indicator_id_to_byte(:zone_5_armed), do: 0x24
  def indicator_id_to_byte(:zone_6_armed), do: 0x25
  def indicator_id_to_byte(:zone_7_armed), do: 0x26
  def indicator_id_to_byte(:zone_8_armed), do: 0x27
  def indicator_id_to_byte(:lcd_backlight), do: 0x30
  def indicator_id_to_byte(:button_backlit_letters), do: 0x40
  def indicator_id_to_byte(:button_backlit_digits), do: 0x41
  def indicator_id_to_byte(:button_backlit_commands), do: 0x42
  def indicator_id_to_byte(:button_1), do: 0x43
  def indicator_id_to_byte(:button_2), do: 0x44
  def indicator_id_to_byte(:button_3), do: 0x45
  def indicator_id_to_byte(:button_4), do: 0x46
  def indicator_id_to_byte(:button_5), do: 0x47
  def indicator_id_to_byte(:button_6), do: 0x48
  def indicator_id_to_byte(:button_7), do: 0x49
  def indicator_id_to_byte(:button_8), do: 0x4A
  def indicator_id_to_byte(:button_9), do: 0x4B
  def indicator_id_to_byte(:button_10), do: 0x4C
  def indicator_id_to_byte(:button_11), do: 0x4D
  def indicator_id_to_byte(:button_12), do: 0x4E
  def indicator_id_to_byte(:node_identify), do: 0x50
  def indicator_id_to_byte(:sound_1), do: 0x60
  def indicator_id_to_byte(:sound_2), do: 0x61
  def indicator_id_to_byte(:sound_3), do: 0x62
  def indicator_id_to_byte(:sound_4), do: 0x63
  def indicator_id_to_byte(:sound_5), do: 0x64
  def indicator_id_to_byte(:sound_6), do: 0x65
  def indicator_id_to_byte(:sound_7), do: 0x66
  def indicator_id_to_byte(:sound_8), do: 0x67
  def indicator_id_to_byte(:sound_9), do: 0x68
  def indicator_id_to_byte(:sound_10), do: 0x69
  def indicator_id_to_byte(:sound_11), do: 0x6A
  def indicator_id_to_byte(:sound_12), do: 0x6B
  def indicator_id_to_byte(:sound_13), do: 0x6C
  def indicator_id_to_byte(:sound_14), do: 0x6D
  def indicator_id_to_byte(:sound_15), do: 0x6E
  def indicator_id_to_byte(:sound_16), do: 0x6F
  def indicator_id_to_byte(:sound_17), do: 0x70
  def indicator_id_to_byte(:sound_18), do: 0x71
  def indicator_id_to_byte(:sound_19), do: 0x72
  def indicator_id_to_byte(:sound_20), do: 0x73
  def indicator_id_to_byte(:sound_21), do: 0x74
  def indicator_id_to_byte(:sound_22), do: 0x75
  def indicator_id_to_byte(:sound_23), do: 0x76
  def indicator_id_to_byte(:sound_24), do: 0x77
  def indicator_id_to_byte(:sound_25), do: 0x78
  def indicator_id_to_byte(:sound_26), do: 0x79
  def indicator_id_to_byte(:sound_27), do: 0x7A
  def indicator_id_to_byte(:sound_28), do: 0x7B
  def indicator_id_to_byte(:sound_29), do: 0x7C
  def indicator_id_to_byte(:sound_30), do: 0x7D
  def indicator_id_to_byte(:sound_31), do: 0x7E
  def indicator_id_to_byte(:sound_32), do: 0x7F
  def indicator_id_to_byte(:buzzer), do: 0xF0
  def indicator_id_to_byte(byte) when byte in 0x00..0xF0, do: byte

  def property_id_to_byte(:undefined), do: 0x00
  def property_id_to_byte(:multilevel), do: 0x01
  def property_id_to_byte(:binary), do: 0x02
  def property_id_to_byte(:toggling_periods), do: 0x03
  def property_id_to_byte(:toggling_cycles), do: 0x04
  def property_id_to_byte(:toggling_on_time), do: 0x05
  def property_id_to_byte(:timeout_minutes), do: 0x06
  def property_id_to_byte(:timeout_seconds), do: 0x07
  def property_id_to_byte(:timeout_hundredths_second), do: 0x08
  def property_id_to_byte(:sound_level), do: 0x09
  def property_id_to_byte(:low_power), do: 0x0A
  def property_id_to_byte(byte) when byte in 0..10, do: byte

  def value_to_byte(:off, :multilevel), do: 0x00
  def value_to_byte(:restore, :multilevel), do: 0xFF
  def value_to_byte(byte, :multilevel) when byte in 0x00..0x63, do: byte
  def value_to_byte(0xFF, :multilevel), do: 0xFF
  def value_to_byte(:off, :binary), do: 0x00
  def value_to_byte(:on, :binary), do: 0xFF
  def value_to_byte(byte, :binary) when byte in 0x00..0x63, do: byte
  def value_to_byte(0xFF, :binary), do: 0xFF
  def value_to_byte(byte, _property_id), do: byte

  def indicator_id_from_byte(0x01), do: {:ok, :armed}
  def indicator_id_from_byte(0x02), do: {:ok, :disarmed}
  def indicator_id_from_byte(0x03), do: {:ok, :ready}
  def indicator_id_from_byte(0x04), do: {:ok, :fault}
  def indicator_id_from_byte(0x05), do: {:ok, :busy}
  def indicator_id_from_byte(0x06), do: {:ok, :enter_id}
  def indicator_id_from_byte(0x07), do: {:ok, :enter_pin}
  def indicator_id_from_byte(0x08), do: {:ok, :code_accepted}
  def indicator_id_from_byte(0x09), do: {:ok, :code_not_accepted}
  def indicator_id_from_byte(0x0A), do: {:ok, :armed_stay}
  def indicator_id_from_byte(0x0B), do: {:ok, :armed_away}
  def indicator_id_from_byte(0x0C), do: {:ok, :alarming}
  def indicator_id_from_byte(0x0D), do: {:ok, :alarming_burglar}
  def indicator_id_from_byte(0x0E), do: {:ok, :alarming_smoke_fire}
  def indicator_id_from_byte(0x0F), do: {:ok, :alarming_co}
  def indicator_id_from_byte(0x10), do: {:ok, :bypass_challenge}
  def indicator_id_from_byte(0x11), do: {:ok, :entry_delay}
  def indicator_id_from_byte(0x12), do: {:ok, :exit_delay}
  def indicator_id_from_byte(0x13), do: {:ok, :alarming_medical}
  def indicator_id_from_byte(0x14), do: {:ok, :alarming_freeze_warning}
  def indicator_id_from_byte(0x15), do: {:ok, :alarming_water_leak}
  def indicator_id_from_byte(0x16), do: {:ok, :alarming_panic}
  def indicator_id_from_byte(0x20), do: {:ok, :zone_1_armed}
  def indicator_id_from_byte(0x21), do: {:ok, :zone_2_armed}
  def indicator_id_from_byte(0x22), do: {:ok, :zone_3_armed}
  def indicator_id_from_byte(0x23), do: {:ok, :zone_4_armed}
  def indicator_id_from_byte(0x24), do: {:ok, :zone_5_armed}
  def indicator_id_from_byte(0x25), do: {:ok, :zone_6_armed}
  def indicator_id_from_byte(0x26), do: {:ok, :zone_7_armed}
  def indicator_id_from_byte(0x27), do: {:ok, :zone_8_armed}
  def indicator_id_from_byte(0x30), do: {:ok, :lcd_backlight}
  def indicator_id_from_byte(0x40), do: {:ok, :button_backlit_letters}
  def indicator_id_from_byte(0x41), do: {:ok, :button_backlit_digits}
  def indicator_id_from_byte(0x42), do: {:ok, :button_backlit_commands}
  def indicator_id_from_byte(0x43), do: {:ok, :button_1}
  def indicator_id_from_byte(0x44), do: {:ok, :button_2}
  def indicator_id_from_byte(0x45), do: {:ok, :button_3}
  def indicator_id_from_byte(0x46), do: {:ok, :button_4}
  def indicator_id_from_byte(0x47), do: {:ok, :button_5}
  def indicator_id_from_byte(0x48), do: {:ok, :button_6}
  def indicator_id_from_byte(0x49), do: {:ok, :button_7}
  def indicator_id_from_byte(0x4A), do: {:ok, :button_8}
  def indicator_id_from_byte(0x4B), do: {:ok, :button_9}
  def indicator_id_from_byte(0x4C), do: {:ok, :button_10}
  def indicator_id_from_byte(0x4D), do: {:ok, :button_11}
  def indicator_id_from_byte(0x4E), do: {:ok, :button_12}
  def indicator_id_from_byte(0x50), do: {:ok, :node_identify}
  def indicator_id_from_byte(0x60), do: {:ok, :sound_1}
  def indicator_id_from_byte(0x61), do: {:ok, :sound_2}
  def indicator_id_from_byte(0x62), do: {:ok, :sound_3}
  def indicator_id_from_byte(0x63), do: {:ok, :sound_4}
  def indicator_id_from_byte(0x64), do: {:ok, :sound_5}
  def indicator_id_from_byte(0x65), do: {:ok, :sound_6}
  def indicator_id_from_byte(0x66), do: {:ok, :sound_7}
  def indicator_id_from_byte(0x67), do: {:ok, :sound_8}
  def indicator_id_from_byte(0x68), do: {:ok, :sound_9}
  def indicator_id_from_byte(0x69), do: {:ok, :sound_10}
  def indicator_id_from_byte(0x6A), do: {:ok, :sound_11}
  def indicator_id_from_byte(0x6B), do: {:ok, :sound_12}
  def indicator_id_from_byte(0x6C), do: {:ok, :sound_13}
  def indicator_id_from_byte(0x6D), do: {:ok, :sound_14}
  def indicator_id_from_byte(0x6E), do: {:ok, :sound_15}
  def indicator_id_from_byte(0x6F), do: {:ok, :sound_16}
  def indicator_id_from_byte(0x70), do: {:ok, :sound_17}
  def indicator_id_from_byte(0x71), do: {:ok, :sound_18}
  def indicator_id_from_byte(0x72), do: {:ok, :sound_19}
  def indicator_id_from_byte(0x73), do: {:ok, :sound_20}
  def indicator_id_from_byte(0x74), do: {:ok, :sound_21}
  def indicator_id_from_byte(0x75), do: {:ok, :sound_22}
  def indicator_id_from_byte(0x76), do: {:ok, :sound_23}
  def indicator_id_from_byte(0x77), do: {:ok, :sound_24}
  def indicator_id_from_byte(0x78), do: {:ok, :sound_25}
  def indicator_id_from_byte(0x79), do: {:ok, :sound_26}
  def indicator_id_from_byte(0x7A), do: {:ok, :sound_27}
  def indicator_id_from_byte(0x7B), do: {:ok, :sound_28}
  def indicator_id_from_byte(0x7C), do: {:ok, :sound_29}
  def indicator_id_from_byte(0x7D), do: {:ok, :sound_30}
  def indicator_id_from_byte(0x7E), do: {:ok, :sound_31}
  def indicator_id_from_byte(0x7F), do: {:ok, :sound_32}
  def indicator_id_from_byte(0xF0), do: {:ok, :buzzer}

  # Devices can return an indicator id == 0
  def indicator_id_from_byte(0x00), do: {:ok, :undefined}
  def indicator_id_from_byte(byte) when byte in 0x80..0x9F, do: {:ok, byte}

  def indicator_id_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :indicator_id, command: nil}}

  def property_id_from_byte(0x01), do: {:ok, :multilevel}
  def property_id_from_byte(0x02), do: {:ok, :binary}
  def property_id_from_byte(0x03), do: {:ok, :toggling_periods}
  def property_id_from_byte(0x04), do: {:ok, :toggling_cycles}
  def property_id_from_byte(0x05), do: {:ok, :toggling_on_time}
  def property_id_from_byte(0x06), do: {:ok, :timeout_minutes}
  def property_id_from_byte(0x07), do: {:ok, :timeout_seconds}
  def property_id_from_byte(0x08), do: {:ok, :timeout_hundredths_second}
  def property_id_from_byte(0x09), do: {:ok, :sound_level}
  def property_id_from_byte(0x0A), do: {:ok, :low_power}
  def property_id_from_byte(0x00), do: {:ok, :undefined}

  def property_id_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :property_id, command: nil}}

  def value_from_byte(0x00, :multilevel), do: {:ok, :off}
  def value_from_byte(0xFF, :multilevel), do: {:ok, :restore}
  def value_from_byte(byte, :multilevel) when byte in 0x01..0x63, do: {:ok, byte}

  def value_from_byte(byte, :multilevel),
    do: {:error, %DecodeError{value: byte, param: :value, command: nil}}

  def value_from_byte(0x00, :binary), do: {:ok, :off}
  def value_from_byte(0xFF, :binary), do: {:ok, :on}

  def value_from_byte(byte, :binary),
    do: {:error, %DecodeError{value: byte, param: :value, command: nil}}

  def value_from_byte(byte, _property_id), do: {:ok, byte}
end
