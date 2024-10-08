defmodule Grizzly.ZWave.Commands.SwitchMultilevelReport do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_REPORT

  Params:

    * `:value` - `:off`, 0 (off) and 99 (100% on), or `:unknown`
    * `:duration` - How long the switch should take to reach target value, 0 -> instantly, 1..127 -> seconds, 128..253 -> minutes, 255 -> unknown (optional v2)
  """

  @behaviour Grizzly.ZWave.Command
  require Logger
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @type param :: {:value, 0..99 | :off | :unknown} | {:duration, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :switch_multilevel_report,
      command_byte: 0x03,
      command_class: SwitchMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    value_byte = encode_value(Command.param!(command, :value))

    case Command.param(command, :duration) do
      nil ->
        <<value_byte>>

      # version 2
      duration_byte ->
        <<value_byte, duration_byte>>
    end
  end

  def encode_value(:off), do: 0x00
  def encode_value(value) when value in 0..99, do: value
  def encode_value(:unknown), do: 0xFE

  @impl Grizzly.ZWave.Command
  def decode_params(<<value_byte>>) do
    case value_from_byte(value_byte) do
      {:ok, value} ->
        {:ok, [value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # version 2
  def decode_params(<<value_byte, duration>>) do
    case value_from_byte(value_byte) do
      {:ok, value} ->
        {:ok, [value: value, duration: duration]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # version 4
  def decode_params(<<value_byte, target_value_byte, duration, rest::binary>>) do
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
         duration: duration
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
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
