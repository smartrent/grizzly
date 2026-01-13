defmodule Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesGet do
  @moduledoc """
  HumidityControlSetpointCapabilitiesGet

  ## Parameters

  * `:setpoint_type`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  @type param :: {:setpoint_type, HumidityControlSetpoint.type()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    setpoint_type = Command.param!(command, :setpoint_type)

    <<0::4, encode_type(setpoint_type)::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, setpoint_type::4>>) do
    {:ok, [setpoint_type: decode_type(setpoint_type)]}
  end
end
