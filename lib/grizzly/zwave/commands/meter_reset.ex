defmodule Grizzly.ZWave.Commands.MeterReset do
  @moduledoc """
  This module implements the command METER_RESET of the METER command class.

  This command is used to reset all accumulated measurements stored at the receiving node to 0 (v1)
  or possibly only a smeasurement to a given value (v6).

  ## Parameters

  * `:meter_type` - the type of metering physical unit being reset (v6)
  * `scale` - the scale of the value (v6)
  * `:rate_type` - whether the import or export value is being reset (v6)
  * `:value` - the value to be reset to (v6)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Encoding}
  alias Grizzly.ZWave.CommandClasses.Meter

  @type param :: {:meter_type, any()} | {:rate_type, any()} | {:values, any()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :meter_reset,
      command_byte: 0x05,
      command_class: Meter,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    if Command.has_param?(command, :meter_type) || Command.has_param?(command, :rate_type) ||
         Command.has_param?(command, :scale) || Command.has_param?(command, :value) do
      rate_type = Command.param!(command, :rate_type)
      meter_type = Command.param!(command, :meter_type)
      value = Command.param!(command, :value)
      scale = Command.param!(command, :scale)
      rate_type_bin = Meter.encode_rate_type(rate_type)
      meter_type_bin = Meter.encode_meter_type(meter_type)
      {scale1, scale2} = Meter.encode_meter_scale(scale, meter_type)
      {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

      <<_::5, scale1_msb::1, scale1_rest::2>> = <<scale1>>

      <<scale1_msb::1, rate_type_bin::2, meter_type_bin::5, precision::3, scale1_rest::2,
        byte_size::3, int_value::size(byte_size)-unit(8), scale2::8>>
    else
      <<>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # v2-v5
  def decode_params(<<>>) do
    {:ok, []}
  end

  # v6
  def decode_params(
        <<scale1_msb::1, rate_type_bin::2, meter_type_bin::5, precision::3, scale1_rest::2,
          size::3, int_value::size(size)-unit(8), scale2::8>>
      ) do
    <<scale1>> = <<0::5, scale1_msb::1, scale1_rest::2>>
    value = Encoding.decode_zwave_float(int_value, precision)

    with {:ok, meter_type} <- Meter.decode_meter_type(meter_type_bin),
         {:ok, rate_type} <- Meter.decode_rate_type(rate_type_bin),
         {:ok, scale} <- Meter.decode_meter_scale({scale1, scale2}, meter_type) do
      {:ok,
       [
         meter_type: meter_type,
         scale: scale,
         value: value,
         rate_type: rate_type
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
