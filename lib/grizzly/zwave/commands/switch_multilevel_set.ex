defmodule Grizzly.ZWave.Commands.SwitchMultilevelSet do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_SET

  Params:

    * `:target_value` - '`:off`, `:previous` or a value between 0 and 99
    * `:duration` - How long the switch should take to reach target value,
      * 0 -> instantly
      * 1..127 -> seconds
      * 128..254 -> minutes + 127
      * 255 -> factory default (option v2)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @type param :: {:target_value, :off | :previous | 0..99} | {:duration, 0..255}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    # TODO: validate opts
    command = %Command{
      name: :switch_multilevel_set,
      command_byte: 0x01,
      command_class: SwitchMultilevel,
      params: params,
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

      duration_byte ->
        <<target_value_byte, duration_byte>>
    end
  end

  def encode_target_value(:off), do: 0x00
  def encode_target_value(:previous), do: 0xFF
  def encode_target_value(0xFF), do: 0xFF
  def encode_target_value(target_value) when target_value > 99, do: 99
  def encode_target_value(target_value) when target_value < 0, do: 0
  def encode_target_value(target_value), do: target_value

  @impl Grizzly.ZWave.Command
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
  defp target_value_from_byte(0xFF), do: {:ok, :previous}
  defp target_value_from_byte(byte) when byte in 0..99, do: {:ok, byte}

  defp target_value_from_byte(byte),
    do:
      {:error,
       %DecodeError{value: byte, param: :target_value, command: :switch_multilevel_report}}
end
