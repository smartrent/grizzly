defmodule Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesReport do
  @moduledoc """
  HumidityControlSetpointCapabilitiesReport

  ## Parameters

  * `:setpoint_type`
  * `:min_value`
  * `:min_scale`
  * `:max_value`
  * `:max_scale`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.HumidityControl
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControl

  @type param ::
          {:setpoint_type, HumidityControl.setpoint_type()}
          | {:min_value, number()}
          | {:min_scale, HumidityControl.setpoint_scale()}
          | {:max_value, number()}
          | {:max_scale, HumidityControl.setpoint_scale()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    setpoint_type = Command.param!(command, :setpoint_type)
    min_value = Command.param!(command, :min_value)
    min_scale = Command.param!(command, :min_scale) |> encode_setpoint_scale()
    max_value = Command.param!(command, :max_value)
    max_scale = Command.param!(command, :max_scale) |> encode_setpoint_scale()

    min_value_bin = zwave_float_to_binary(min_value, min_scale)
    max_value_bin = zwave_float_to_binary(max_value, max_scale)

    <<0::4, encode_setpoint_type(setpoint_type)::4>> <> min_value_bin <> max_value_bin
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<_::4, setpoint_type::4, min_precision::3, min_scale::2, min_bytes::3,
          min_value::signed-size(min_bytes * 8), max_precision::3, max_scale::2, max_bytes::3,
          max_value::signed-size(max_bytes * 8)>>
      ) do
    min_value = decode_zwave_float(min_value, min_precision)
    min_scale = decode_setpoint_scale(min_scale)
    max_value = decode_zwave_float(max_value, max_precision)
    max_scale = decode_setpoint_scale(max_scale)

    {:ok,
     [
       setpoint_type: decode_setpoint_type(setpoint_type),
       min_value: min_value,
       min_scale: min_scale,
       max_value: max_value,
       max_scale: max_scale
     ]}
  end
end
