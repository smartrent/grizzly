defmodule Grizzly.ZWave.Commands.SwitchBinaryReport do
  @moduledoc """
  Module for the SWITCH_BINARY_REPORT command

  Params:

    * `:target_value` - `:on`, `:off`, or `:unknown` (required)
    * `:duration` - 0-255 (required V2)
    * `:current_value` - `:on`, `:off`, or `:unknown` (required V2)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SwitchBinary

  @type value() :: :on | :off | :unknown

  @type param() :: {:target_value, value()} | {:duration, byte()} | {:current_value, value()}

  @impl Grizzly.ZWave.Command
  def new(opts) do
    # TODO: validate opts
    command = %Command{
      name: :switch_binary_report,
      command_byte: 0x03,
      command_class: SwitchBinary,
      params: opts,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    target_value_byte = encode_target_value(Command.param!(command, :target_value))

    case Command.param(command, :current_value) do
      nil ->
        <<target_value_byte>>

      current_value ->
        duration = Command.param!(command, :duration)
        current_value_byte = encode_target_value(current_value)
        <<current_value_byte, target_value_byte, duration>>
    end
  end

  def encode_target_value(:off), do: 0x00
  def encode_target_value(:unknown), do: 0xFE
  def encode_target_value(:on), do: 0xFF

  @impl Grizzly.ZWave.Command
  def decode_params(<<target_value_byte>>) do
    case value_from_byte(target_value_byte) do
      {:ok, target_value} ->
        {:ok, [target_value: target_value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def decode_params(<<current_value, target_value, duration>>) do
    with {:ok, target_value} <- value_from_byte(target_value),
         {:ok, current_value} <- value_from_byte(current_value) do
      {:ok,
       [
         target_value: target_value,
         duration: duration,
         current_value: current_value
       ]}
    end
  end

  defp value_from_byte(0x00), do: {:ok, :off}
  defp value_from_byte(0xFE), do: {:ok, :unknown}
  defp value_from_byte(0xFF), do: {:ok, :on}

  defp value_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :target_value, command: :switch_binary_report}}
end
