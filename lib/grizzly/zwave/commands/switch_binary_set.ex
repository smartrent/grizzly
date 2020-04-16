defmodule Grizzly.ZWave.Commands.SwitchBinarySet do
  @moduledoc """
  Module for the SWITCH_BINARY_SET command

  Params:

    * `:target_value` - `:on` or `:off`(required)
    * `:duration` - 0-255 (optional v2)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SwitchBinary

  @type param :: {:target_value, non_neg_integer()} | {:duration, non_neg_integer()}

  @impl true
  def new(opts) do
    # TODO: validate opts
    command = %Command{
      name: :switch_binary_set,
      command_byte: 0x01,
      command_class: SwitchBinary,
      params: opts,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    target_value_byte = encode_target_value(Command.param!(command, :target_value))

    case Command.param(command, :duration) do
      nil ->
        <<target_value_byte>>

      duration_byte ->
        <<target_value_byte, duration_byte>>
    end
  end

  def encode_target_value(:off), do: 0x00
  def encode_target_value(:on), do: 0xFF

  @impl true
  def decode_params(<<target_value_byte>>) do
    case target_value_from_byte(target_value_byte) do
      {:ok, target_value} ->
        {:ok, [target_value: target_value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def decode_params(<<target_value_byte, duration>>) do
    case target_value_from_byte(target_value_byte) do
      {:ok, target_value} ->
        {:ok, [target_value: target_value, duration: duration]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp target_value_from_byte(0x00), do: {:ok, :off}
  defp target_value_from_byte(0xFF), do: {:ok, :on}

  defp target_value_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :target_value, command: :switch_binary_report}}
end
