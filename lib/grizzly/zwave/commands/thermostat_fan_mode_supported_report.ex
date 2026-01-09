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
  alias Grizzly.ZWave.DecodeError

  @type param :: {:modes, [ThermostatFanMode.mode()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    command
    |> Command.param!(:modes)
    |> Enum.map(&ThermostatFanMode.encode_mode/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
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
