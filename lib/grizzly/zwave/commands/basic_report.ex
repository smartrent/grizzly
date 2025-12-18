defmodule Grizzly.ZWave.Commands.BasicReport do
  @moduledoc """
  This module implements the BASIC_REPORT command of the COMMAND_CLASS_BASIC
  command class

  Params:

    * `:value` - the current value (:on or :off or :unknown)
    * `:target_value` - the target value (:on or :off or :unknown) - v2
    * `:duration` - the time in seconds needed to reach the Target Value at the
      actual transition rate - v2
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Basic
  alias Grizzly.ZWave.DecodeError

  @type value :: :on | :off | :unknown | byte()
  @type duration :: non_neg_integer | :unknown
  @type param :: {:value, value()} | {:target_value, value()} | {:duration, duration()}

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
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
         {:ok, target_value} <- value_from_byte(target_value_byte, :target_value) do
      {:ok, [value: value, target_value: target_value, duration: decode_duration(duration_byte)]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_value(:on), do: 0xFF
  defp encode_value(:off), do: 0x00
  defp encode_value(:unknown), do: 0xFE
  defp encode_value(value) when is_integer(value), do: value

  defp value_from_byte(0x00, _param), do: {:ok, :off}
  defp value_from_byte(0xFF, _param), do: {:ok, :on}
  defp value_from_byte(0xFE, _param), do: {:ok, :unknown}
  defp value_from_byte(byte, _param) when byte in 0x01..0x63, do: {:ok, :on}

  defp value_from_byte(byte, param),
    do: {:error, %DecodeError{value: byte, param: param, command: :basic_report}}
end
