defmodule Grizzly.ZWave.Commands.ThermostatFanModeReport do
  @moduledoc """
  This module implement command THERMOSTAT_FAN_MODE_REPORT of the
  COMMAND_CLASS_THERMOSTAT_FAN_MODE command class

  This command is used to report the fan mode.

  Params:

    * `:mode` - one of :auto_low | :low | :auto_high | :high (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatFanMode

  @type param :: {:mode, ThermostatFanMode.mode()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_fan_mode_report,
      command_byte: 0x03,
      command_class: ThermostatFanMode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    mode_byte = Command.param!(command, :mode) |> ThermostatFanMode.encode_mode()
    <<0x00::4, mode_byte::4>>
  end

  @impl true
  def decode_params(<<_::4, mode_byte::4>>) do
    with {:ok, mode} <- ThermostatFanMode.decode_mode(mode_byte) do
      {:ok, [mode: mode]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
