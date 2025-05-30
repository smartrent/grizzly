defmodule Grizzly.ZWave.Commands.SwitchBinarySet do
  @moduledoc """
  Module for the SWITCH_BINARY_SET command

  Params:

  * `:target_value` - `:on` or `:off`(required)
  * `:duration` - How long in seconds the switch should take to reach target value or the factory default (:default)
                  Beyond 127 seconds, the duration is truncated to the minute. E.g. 179s is 2 minutes and 180s is 3 minutes
                  (optional V2)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.{SwitchBinary, SwitchSupport}

  @type param :: {:target_value, :on | :off} | {:duration, SwitchSupport.duration()}

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    target_value_byte = encode_target_value(Command.param!(command, :target_value))

    case Command.param(command, :duration) do
      nil ->
        <<target_value_byte>>

      duration ->
        duration_byte = SwitchSupport.duration_to_byte(duration)
        <<target_value_byte, duration_byte>>
    end
  end

  def encode_target_value(:off), do: 0x00
  def encode_target_value(:on), do: 0xFF

  @impl Grizzly.ZWave.Command
  def decode_params(<<target_value_byte>>) do
    case target_value_from_byte(target_value_byte) do
      {:ok, target_value} ->
        {:ok, [target_value: target_value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def decode_params(<<target_value_byte, duration_byte>>) do
    with {:ok, target_value} <- target_value_from_byte(target_value_byte),
         {:ok, duration} <- SwitchSupport.duration_from_byte(duration_byte) do
      {:ok, [target_value: target_value, duration: duration]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp target_value_from_byte(0x00), do: {:ok, :off}
  defp target_value_from_byte(0xFF), do: {:ok, :on}

  defp target_value_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :target_value, command: :switch_binary_report}}
end
