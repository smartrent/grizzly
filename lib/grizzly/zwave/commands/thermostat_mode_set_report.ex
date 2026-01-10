defmodule Grizzly.ZWave.Commands.ThermostatModeSetReport do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_SET of the
  COMMAND_CLASS_THERMOSTAT_MODE command class.

  This command is used to set the mode from the thermostat device.

  Params:

    * `:mode` - the mode of the thermostat, see ThermostatMode (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:mode, ThermostatMode.mode()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    mode = Command.param!(command, :mode)

    if mode == :manufacturer_specific do
      mfr_data = Command.param!(command, :manufacturer_data)

      if byte_size(mfr_data) > 7 do
        raise ArgumentError, "ThermostatModeSet manufacturer_data must be <= 7 bytes"
      end

      mfr_data_len = byte_size(mfr_data)

      <<mfr_data_len::3, ThermostatMode.encode_mode(:manufacturer_specific)::5,
        mfr_data::binary-size(mfr_data_len)>>
    else
      mode_byte = ThermostatMode.encode_mode(Command.param!(command, :mode))
      <<0x00::3, mode_byte::5>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<mfr_data_len::3, mode_byte::5, mfr_data::binary-size(mfr_data_len)>>) do
    with {:ok, mode} <- ThermostatMode.decode_mode(mode_byte) do
      if mode == :manufacturer_specific do
        {:ok, [mode: mode, manufacturer_data: mfr_data]}
      else
        {:ok, [mode: mode]}
      end
    end
  end
end
