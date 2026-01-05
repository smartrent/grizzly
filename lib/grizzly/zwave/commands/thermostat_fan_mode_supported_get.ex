defmodule Grizzly.ZWave.Commands.ThermostatFanModeSupportedGet do
  @moduledoc """
  This command is used to request the supported modes from the device.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatFanMode
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_fan_mode_supported_get,
      command_byte: 0x04,
      command_class: ThermostatFanMode,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [keyword()]} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
