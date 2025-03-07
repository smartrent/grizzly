defmodule Grizzly.ZWave.CommandClasses.SwitchSupport do
  @moduledoc """
  Support for Switch Binary and Switch Multilevel Command Classes
  """

  alias Grizzly.ZWave.DecodeError

  # Duration in seconds, or the manufacturer's default
  @type duration :: :default | 0..7620

  # Duration encoding
  #   * 0 -> instantly
  #   * 1..127 -> seconds
  #   * 128..254 -> minutes + 127
  #   * 255 -> factory default (option v2)
  @doc """
  Encode a duration into a byte according to the Z-Wave specs
  """
  @spec duration_to_byte(duration()) :: byte()
  def duration_to_byte(:default), do: 255
  def duration_to_byte(seconds) when seconds in 0..127, do: seconds

  def duration_to_byte(seconds) when seconds in 128..7620 do
    minutes = div(seconds, 60)
    127 + minutes
  end

  # Force duration values within supported bounds
  def duration_to_byte(seconds) when seconds > 7620, do: 254
  def duration_to_byte(seconds) when seconds < 0, do: 0

  @doc """
  Decode a duration from a byte according to the Z-Wave specs
  """
  @spec duration_from_byte(byte()) ::
          {:error, DecodeError.t()} | {:ok, duration()}
  def duration_from_byte(255), do: {:ok, :default}
  def duration_from_byte(byte) when byte in 0..127, do: {:ok, byte}
  def duration_from_byte(byte) when byte in 128..254, do: {:ok, (byte - 127) * 60}

  def duration_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :duration, command: :switch_multilevel_report}}
end
