defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedReport do
  @moduledoc """
  This command is used to report the thermostat's supported modes.

  Params:

    * `:modes` - A list of supported modes. See `t:Grizzly.ZWave.CommandClasses.ThermostatMode.mode/0`.

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:modes, [{ThermostatMode.mode(), boolean()}]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_mode_supported_report,
      command_byte: 0x05,
      command_class: ThermostatMode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    modes = Command.param!(command, :modes)

    encode_indexed_bitmask(modes, &ThermostatMode.encode_mode/1)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    modes = decode_indexed_bitmask(binary, &decode_mode/1)
    {:ok, [modes: modes]}
  end

  defp decode_mode(mode) do
    case ThermostatMode.decode_mode(mode) do
      {:ok, v} -> v
      _ -> nil
    end
  end
end
