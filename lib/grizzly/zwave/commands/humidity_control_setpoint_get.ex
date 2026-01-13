defmodule Grizzly.ZWave.Commands.HumidityControlSetpointGet do
  @moduledoc """
  HumidityControlSetpointGet

  ## Parameters

  * `:setpoint_type` - see `t:HumidityControlSetpoint.type/0`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  @type param :: {:setpoint_type, HumidityControlSetpoint.type()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    type = Command.param!(command, :setpoint_type)
    <<0::4, encode_type(type)::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, type::4>>) do
    {:ok, [setpoint_type: decode_type(type)]}
  end
end
