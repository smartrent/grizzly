defmodule Grizzly.ZWave.Commands.ThermostatModeReport do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_REPORT of the
  COMMAND_CLASS_THERMOSTAT_MODE command class.

  This command is used to report the mode from the thermostat device.

  Params:

    * `:mode` - the mode of the thermostat, see ThermostatMode (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:mode, ThermostatMode.mode()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_mode_report,
      command_byte: 0x03,
      command_class: ThermostatMode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    mode_byte = ThermostatMode.encode_mode(Command.param!(command, :mode))
    <<0x00::3, mode_byte::5>>
  end

  @impl true
  # version 1
  def decode_params(<<0x00::3, mode_byte::5, _::binary>>) do
    with {:ok, mode} <- ThermostatMode.decode_mode(mode_byte) do
      {:ok, [mode: mode]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
