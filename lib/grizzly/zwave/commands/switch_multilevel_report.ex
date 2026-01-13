defmodule Grizzly.ZWave.Commands.SwitchMultilevelReport do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_REPORT

  Params:

    * `:value` - `:off`, 0 (off) and 99 (100% on), or `:unknown`
    * `:duration` - How long in seconds the switch should take to reach target value or the factory default (:default)
                    Beyond 127 seconds, the duration is truncated to the minute. E.g. 179s is 2 minutes and 180s is 3 minutes
                    (optional v2)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  require Logger

  @type param :: {:value, 0..99 | :off | :unknown} | {:duration, Encoding.duration()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    value_byte = encode_value(Command.param!(command, :value))

    case Command.param(command, :duration) do
      nil ->
        <<value_byte>>

      # version 2
      duration ->
        duration_byte = encode_duration(duration)
        <<value_byte, duration_byte>>
    end
  end

  def encode_value(:off), do: 0x00
  def encode_value(value) when value in 0..99, do: value
  def encode_value(:unknown), do: 0xFE

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<value_byte>>) do
    case value_from_byte(value_byte) do
      {:ok, value} ->
        {:ok, [value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # version 2
  def decode_params(_spec, <<value_byte, duration_byte>>) do
    with {:ok, value} <- value_from_byte(value_byte) do
      {:ok, [value: value, duration: decode_duration(duration_byte)]}
    end
  end

  # version 4
  def decode_params(_spec, <<value_byte, target_value_byte, duration_byte, rest::binary>>) do
    if byte_size(rest) > 0 do
      Logger.warning(
        "[Grizzly] Unexpected trailing bytes in SwitchMultilevelReport: #{inspect(rest)}"
      )
    end

    with {:ok, value} <- value_from_byte(value_byte),
         {:ok, target_value} <- value_from_byte(target_value_byte) do
      {:ok,
       [
         value: value,
         target_value: target_value,
         duration: decode_duration(duration_byte)
       ]}
    end
  end

  defp value_from_byte(0x00), do: {:ok, :off}
  defp value_from_byte(byte) when byte in 1..99, do: {:ok, byte}
  defp value_from_byte(0xFE), do: {:ok, :unknown}
  # deprecated
  # 99 means 100% hardware level
  defp value_from_byte(0xFF), do: {:ok, 99}
  # Leviton DZ1KD-1BZ dimmer
  defp value_from_byte(100), do: {:ok, 99}

  defp value_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :value, command: :switch_multilevel_report}}
end
