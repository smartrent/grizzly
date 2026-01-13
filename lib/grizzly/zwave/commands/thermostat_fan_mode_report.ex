defmodule Grizzly.ZWave.Commands.ThermostatFanModeReport do
  @moduledoc """
  This module implement command THERMOSTAT_FAN_MODE_REPORT of the
  COMMAND_CLASS_THERMOSTAT_FAN_MODE command class

  This command is used to report the fan mode.

  Params:

    * `:mode` - one of :auto_low | :low | :auto_high | :high (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatFanMode
  alias Grizzly.ZWave.DecodeError

  @type param :: {:mode, ThermostatFanMode.mode()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    mode_byte = Command.param!(command, :mode) |> ThermostatFanMode.encode_mode()
    <<0x00::4, mode_byte::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, mode_byte::4>>) do
    with {:ok, mode} <- ThermostatFanMode.decode_mode(mode_byte) do
      {:ok, [mode: mode]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
