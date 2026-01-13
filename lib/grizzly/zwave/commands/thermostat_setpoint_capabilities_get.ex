defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesGet do
  @moduledoc """
  This command is used request the supported setpoint value range for a setpoint type.

  ## Parameters

  * `:type` - The setpoint type to query capabilities for.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param() :: {:type, ThermostatSetpoint.type()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    type = Command.param!(command, :type)
    <<0::4, ThermostatSetpoint.encode_type(type)::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_reserved::4, type::4>>) do
    {:ok, [type: ThermostatSetpoint.decode_type(type)]}
  end
end
