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

  import Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:setpoint_type, HumidityControlSetpoint.type()}
          | {:min_value, number()}
          | {:min_scale, HumidityControlSetpoint.scale()}
          | {:max_value, number()}
          | {:max_scale, HumidityControlSetpoint.scale()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_setpoint_capabilities_report,
      command_byte: 0x09,
      command_class: HumidityControlSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    setpoint_type = Command.param!(command, :setpoint_type)
    min_value = Command.param!(command, :min_value)
    min_scale = Command.param!(command, :min_scale) |> encode_scale()
    max_value = Command.param!(command, :max_value)
    max_scale = Command.param!(command, :max_scale) |> encode_scale()

    min_value_bin = zwave_float_to_binary(min_value, min_scale)
    max_value_bin = zwave_float_to_binary(max_value, max_scale)

    <<0::4, encode_type(setpoint_type)::4>> <> min_value_bin <> max_value_bin
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<_::4, setpoint_type::4, min_precision::3, min_scale::2, min_bytes::3,
          min_value::signed-size(min_bytes * 8), max_precision::3, max_scale::2, max_bytes::3,
          max_value::signed-size(max_bytes * 8)>>
      ) do
    min_value = decode_zwave_float(min_value, min_precision)
    min_scale = decode_scale(min_scale)
    max_value = decode_zwave_float(max_value, max_precision)
    max_scale = decode_scale(max_scale)

    {:ok,
     [
       setpoint_type: decode_type(setpoint_type),
       min_value: min_value,
       min_scale: min_scale,
       max_value: max_value,
       max_scale: max_scale
     ]}
  end
end
