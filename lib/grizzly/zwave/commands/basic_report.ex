defmodule Grizzly.ZWave.Commands.BasicReport do
  @moduledoc """
  This module implements the BASIC_REPORT command of the COMMAND_CLASS_BASIC command class

  Params:

    * `:value` - the current value (:on or :off or :unknown)
    * `:target_value` - the target value (:on or :off or :unknown) - v2
    * `:duration` - the time in seconds needed to reach the Target Value at the actual transition rate - v2

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Basic

  @type value :: :on | :off | :unknown
  @type duration :: non_neg_integer | :unknown
  @type param :: {:value, value()} | {:target_value, value()} | {:duration, duration()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :basic_report,
      command_byte: 0x03,
      command_class: Basic,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    value_byte = Command.param!(command, :value) |> encode_value()
    target_value = Command.param(command, :target_value)

    if target_value == nil do
      <<value_byte>>
    else
      duration_byte = Command.param!(command, :duration) |> encode_duration()
      target_value_byte = encode_value(target_value)
      <<value_byte, target_value_byte, duration_byte>>
    end
  end

  @impl true
  # v1
  def decode_params(<<value_byte>>) do
    case value_from_byte(value_byte, :value) do
      {:ok, value} ->
        {:ok, [value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # v2
  def decode_params(<<value_byte, target_value_byte, duration_byte>>) do
    with {:ok, value} <- value_from_byte(value_byte, :value),
         {:ok, target_value} <- value_from_byte(target_value_byte, :target_value),
         {:ok, duration} <- duration_from_byte(duration_byte) do
      {:ok, [value: value, target_value: target_value, duration: duration]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_value(:on), do: 0xFF
  defp encode_value(:off), do: 0x00
  defp encode_value(:unknown), do: 0xFE

  defp encode_duration(secs) when is_number(secs) and secs in 0..127, do: secs

  defp encode_duration(secs) when is_number(secs) and secs in 128..(126 * 60),
    do: 0x80 + div(secs, 60)

  defp encode_duration(:unknown), do: 0xFE
  defp encode_duration(_), do: 0xFE

  defp value_from_byte(0x00, _param), do: {:ok, :off}
  defp value_from_byte(0xFF, _param), do: {:ok, :on}
  defp value_from_byte(0xFE, _param), do: {:ok, :unknown}

  defp value_from_byte(byte, param),
    do: {:error, %DecodeError{value: byte, param: param, command: :basic_report}}

  defp duration_from_byte(duration_byte) when duration_byte in 0x00..0x7F,
    do: {:ok, duration_byte}

  defp duration_from_byte(duration_byte) when duration_byte in 0x80..0xFD,
    do: {:ok, (duration_byte - 0x80 + 1) * 60}

  defp duration_from_byte(0xFE), do: {:ok, :unknown}

  defp duration_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :duration, command: :basic_report}}
end
