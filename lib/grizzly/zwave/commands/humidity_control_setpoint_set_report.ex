defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSetReport do
  @moduledoc """
  HumidityControlSetpointSet

  ## Parameters

  * `:setpoint_type` - see `t:HumidityControlSetpoint.type/0`
  * `:scale` - see `t:HumidityControlSetpoint.scale/0`
  * `:value` - setpoint value
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  @type param ::
          {:setpoint_type, HumidityControlSetpoint.type()}
          | {:scale, HumidityControlSetpoint.scale()}
          | {:value, number()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    type = Command.param!(command, :setpoint_type)
    scale = Command.param!(command, :scale)
    value = Command.param!(command, :value)

    <<0::4, encode_type(type)::4>> <> zwave_float_to_binary(value, encode_scale(scale))
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<_::4, type::4, precision::3, scale::2, bytes::3, int_value::signed-size(bytes * 8)>>
      ) do
    type = decode_type(type)
    scale = decode_scale(scale)
    value = decode_zwave_float(int_value, precision)

    {:ok, [setpoint_type: type, scale: scale, value: value]}
  end
end
