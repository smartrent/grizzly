defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedReport do
  @moduledoc """
  This command is used to report the thermostat's supported modes.

  Params:

    * `:modes` - A list of supported modes. See `t:Grizzly.ZWave.CommandClasses.ThermostatMode.mode/0`.

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:modes, [{ThermostatMode.mode(), boolean()}]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    modes = Command.param!(command, :modes)

    modes
    |> Enum.map(&ThermostatMode.encode_mode/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    modes = binary |> decode_bitmask() |> Enum.map(&decode_mode/1)
    {:ok, [modes: modes]}
  end

  defp decode_mode(mode) do
    case ThermostatMode.decode_mode(mode) do
      {:ok, v} -> v
      _ -> nil
    end
  end
end
