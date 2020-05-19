defmodule Grizzly.ZWave.CommandClasses.SensorBinary do
  @moduledoc """
  Deprecated command class for triggered/not triggered sensors.
  """

  @behaviour Grizzly.ZWave.CommandClass
  alias Grizzly.ZWave.DecodeError

  @type sensor_type ::
          :general_purpose
          | :smoke
          | :co
          | :co2
          | :heat
          | :water
          | :freeze
          | :tamper
          | :aux
          | :door_window
          | :tilt
          | :motion
          | :glass_break

  @impl true
  def byte(), do: 0x30

  @impl true
  def name(), do: :sensor_binary

  def encode_type(:general_purpose), do: 0x01
  def encode_type(:smoke), do: 0x02
  def encode_type(:co), do: 0x03
  def encode_type(:co2), do: 0x04
  def encode_type(:heat), do: 0x05
  def encode_type(:water), do: 0x06
  def encode_type(:freeze), do: 0x07
  def encode_type(:tamper), do: 0x08
  def encode_type(:aux), do: 0x09
  def encode_type(:door_window), do: 0x0A
  def encode_type(:tilt), do: 0x0B
  def encode_type(:motion), do: 0x0C
  def encode_type(:glass_break), do: 0x0D

  def decode_type(0x01), do: {:ok, :general_purpose}
  def decode_type(0x02), do: {:ok, :smoke}
  def decode_type(0x03), do: {:ok, :co}
  def decode_type(0x04), do: {:ok, :co2}
  def decode_type(0x05), do: {:ok, :heat}
  def decode_type(0x06), do: {:ok, :water}
  def decode_type(0x07), do: {:ok, :freeze}
  def decode_type(0x08), do: {:ok, :tamper}
  def decode_type(0x09), do: {:ok, :aux}
  def decode_type(0x0A), do: {:ok, :door_window}
  def decode_type(0x0B), do: {:ok, :tilt}
  def decode_type(0x0C), do: {:ok, :glass_break}
  def decode_type(0x0D), do: {:ok, :glass_break}

  def decode_type(byte),
    do: {:error, %DecodeError{value: byte, param: :sensor_type, command: :sensor_binary}}
end
