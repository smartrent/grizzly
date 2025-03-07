defmodule Grizzly.ZWave.CommandClasses.SwitchBinary do
  @moduledoc """
  Switch Binary Command Class

  This command class provides command work with switches that are either on
  or off.
  """

  alias Grizzly.ZWave.DecodeError

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x25

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :switch_binary

  # Duration encoding
  #   * 0 -> instantly
  #   * 1..127 -> seconds
  #   * 128..254 -> minutes + 127
  #   * 255 -> factory default (option v2)
  def duration_to_byte(:default), do: 255
  def duration_to_byte(seconds) when seconds in 0..127, do: seconds

  def duration_to_byte(seconds) when seconds in 128..7620 do
    minutes = div(seconds, 60)
    127 + minutes
  end

  def duration_from_byte(255), do: {:ok, :default}
  def duration_from_byte(byte) when byte in 0..127, do: {:ok, byte}
  def duration_from_byte(byte) when byte in 128..254, do: {:ok, (byte - 127) * 60}

  def duration_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :duration, command: :switch_multilevel_report}}
end
