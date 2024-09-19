defmodule Grizzly.ZWave.CommandClasses.CentralScene do
  @moduledoc """
  "CentralScene" Command Class

  The Central Scene Command Class is used to communicate central scene activations to a central
  controller
  """

  @behaviour Grizzly.ZWave.CommandClass

  @type key_attributes :: [key_attribute]
  @type key_attribute ::
          :key_pressed_1_time
          | :key_released
          | :key_held_down
          | :key_pressed_2_times
          | :key_pressed_3_times
          | :key_pressed_4_times
          | :key_pressed_5_times

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x5B

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :central_scene

  def validate_supported_key_attributes(
        [scene_1_keys | other_scene_keys] = supported_attribute_keys,
        supported_scenes,
        identical?
      )
      when is_list(scene_1_keys) do
    if identical? do
      true = Enum.empty?(other_scene_keys)
    else
      true = Enum.count(supported_attribute_keys) == supported_scenes
    end

    supported_attribute_keys
  end

  def key_attribute_to_bit_index(:key_pressed_1_time), do: {1, 0}
  def key_attribute_to_bit_index(:key_released), do: {1, 1}
  def key_attribute_to_bit_index(:key_held_down), do: {1, 2}
  def key_attribute_to_bit_index(:key_pressed_2_times), do: {1, 3}
  def key_attribute_to_bit_index(:key_pressed_3_times), do: {1, 4}
  def key_attribute_to_bit_index(:key_pressed_4_times), do: {1, 5}
  def key_attribute_to_bit_index(:key_pressed_5_times), do: {1, 6}

  def key_attribute_from_bit_index(1, 0), do: :key_pressed_1_time
  def key_attribute_from_bit_index(1, 1), do: :key_released
  def key_attribute_from_bit_index(1, 2), do: :key_held_down
  def key_attribute_from_bit_index(1, 3), do: :key_pressed_2_times
  def key_attribute_from_bit_index(1, 4), do: :key_pressed_3_times
  def key_attribute_from_bit_index(1, 5), do: :key_pressed_4_times
  def key_attribute_from_bit_index(1, 6), do: :key_pressed_5_times
  def key_attribute_from_bit_index(_byte, _bit), do: :unknown

  def key_attribute_to_byte(key_attribute) do
    {_byte, bit_index} = key_attribute_to_bit_index(key_attribute)
    bit_index
  end

  def key_attribute_from_byte(byte) do
    key_attribute_from_bit_index(1, byte)
  end
end
