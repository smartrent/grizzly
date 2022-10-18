defmodule Grizzly.ZWave.CommandClasses.Clock do
  @moduledoc """
  "Clock" Command Class

  The Clock Command Class is used to implement a simple clock functionality.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type weekday ::
          :sunday | :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :unknown

  @impl true
  def byte(), do: 0x81

  @impl true
  def name(), do: :clock

  @spec encode_weekday(weekday()) :: byte
  def encode_weekday(weekday) do
    case weekday do
      :unknown -> 0x00
      :monday -> 0x01
      :tuesday -> 0x02
      :wednesday -> 0x03
      :thursday -> 0x04
      :friday -> 0x05
      :saturday -> 0x06
      :sunday -> 0x07
    end
  end

  @spec decode_weekday(byte()) :: {:ok, weekday()} | {:error, DecodeError.t()}
  def decode_weekday(byte) do
    case byte do
      0x00 -> {:ok, :unknown}
      0x01 -> {:ok, :monday}
      0x02 -> {:ok, :tuesday}
      0x03 -> {:ok, :wednesday}
      0x04 -> {:ok, :thursday}
      0x05 -> {:ok, :friday}
      0x06 -> {:ok, :saturday}
      0x07 -> {:ok, :sunday}
      byte -> {:error, %DecodeError{param: :weekday, value: byte}}
    end
  end
end
