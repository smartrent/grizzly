defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesGet do
  @moduledoc """
  This command is used request the supported setpoint value range for a setpoint type.

  ## Parameters

  * `:type` - The setpoint type to query capabilities for.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param() :: {:type, ThermostatSetpoint.type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_capabilities_get,
      command_byte: 0x09,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type = Command.param!(command, :type)
    <<0::4, ThermostatSetpoint.encode_type(type)::4>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved::4, type::4>>) do
    {:ok, [type: ThermostatSetpoint.decode_type(type)]}
  end
end
