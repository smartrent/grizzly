defmodule Grizzly.ZWave.Commands.ThermostatModeReport do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_REPORT of the
  COMMAND_CLASS_THERMOSTAT_MODE command class.

  This command is used to report the mode from the thermostat device.

  Params:

    * `:mode` - the mode of the thermostat, see ThermostatMode (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:mode, ThermostatMode.mode()}

  @impl Grizzly.ZWave.Command
  defdelegate encode_params(command), to: Grizzly.ZWave.Commands.ThermostatModeSet

  @impl Grizzly.ZWave.Command
  defdelegate decode_params(binary), to: Grizzly.ZWave.Commands.ThermostatModeSet
end
