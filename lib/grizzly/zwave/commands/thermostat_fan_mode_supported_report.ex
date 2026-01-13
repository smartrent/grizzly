defmodule Grizzly.ZWave.Commands.ThermostatFanModeSupportedReport do
  @moduledoc """
  This command is used to report the device's supported thermostat modes.

  ## Parameters

  * `:modes` - the supported modes
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatFanMode

  @type param :: {:modes, [ThermostatFanMode.mode()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command
    |> Command.param!(:modes)
    |> Enum.map(&ThermostatFanMode.encode_mode/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    modes =
      binary
      |> decode_bitmask()
      |> Enum.reduce([], fn mode, modes ->
        case ThermostatFanMode.decode_mode(mode) do
          {:ok, mode} -> [mode | modes]
          {:error, _} -> modes
        end
      end)
      |> Enum.reverse()

    {:ok, [modes: modes]}
  end
end
