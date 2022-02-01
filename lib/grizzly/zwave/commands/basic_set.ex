defmodule Grizzly.ZWave.Commands.BasicSet do
  @moduledoc """
  This module implements the BASIC_SET command of the COMMAND_CLASS_BASIC
  command class

  Params:

    * `:value` - :on or :off

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Basic

  @type param :: {:value, :on | :off}

  @impl true
  def new(params) do
    command = %Command{
      name: :basic_set,
      command_byte: 0x01,
      command_class: Basic,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    value_byte = encode_value(Command.param!(command, :value))
    <<value_byte>>
  end

  @impl true
  def decode_params(<<value_byte>>) do
    case value_from_byte(value_byte) do
      {:ok, value} ->
        {:ok, [value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_value(:on), do: 0xFF
  defp encode_value(:off), do: 0x00

  defp value_from_byte(0x00), do: {:ok, :off}
  defp value_from_byte(0xFF), do: {:ok, :on}
  defp value_from_byte(byte) when byte in 0x01..0x63, do: {:ok, :on}

  defp value_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :value, command: :basic_set}}
end
