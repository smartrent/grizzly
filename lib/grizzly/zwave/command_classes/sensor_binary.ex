defmodule Grizzly.ZWave.CommandClasses.SensorBinary do
  @moduledoc """
  Deprecated command class for triggered/not triggered sensors.
  """

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.DecodeError

  @type sensor_type() ::
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

  @doc """
  Encode the type value for the sensor report
  """
  @spec encode_type(sensor_type()) :: byte()
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

  @doc """
  Parse the type value from a byte
  """
  @spec decode_type(byte()) :: {:ok, sensor_type()} | {:error, DecodeError.t()}
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
  def decode_type(0x0C), do: {:ok, :motion}
  def decode_type(0x0D), do: {:ok, :glass_break}

  def decode_type(byte),
    do: {:error, %DecodeError{value: byte, param: :sensor_type, command: :sensor_binary}}

  @doc """
  Decode a list of sensor types from a bitmap.

  ## Examples

      iex> decode_sensor_types(<<0x40, 0x00>>)
      {:ok, sensor_types: [:water]}
  """
  @spec decode_sensor_types(binary) :: {:ok, [sensor_types: [atom]]} | {:error, DecodeError.t()}
  def decode_sensor_types(binary) do
    sensor_types =
      binary
      |> decode_bitmask()
      |> Enum.map(fn value ->
        case decode_type(value) do
          {:ok, type} -> type
          {:error, _error} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, [sensor_types: sensor_types]}
  end

  @doc """
  Encode a list of sensor types as a bitmap.

  ## Examples

      iex> encode_sensor_types([:water])
      <<0x40, 0x00>>
  """
  @spec encode_sensor_types([atom]) :: binary
  def encode_sensor_types(sensor_types) do
    sensor_types
    |> Enum.map(&encode_type/1)
    |> encode_bitmask(min_bytes: 2)
  end
end
