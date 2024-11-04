defmodule Grizzly.ZWave.Commands.MeterReport do
  @moduledoc """
  This module implements the command METER_REPORT of the COMMAND_CLASS_METER command ,
  which is used to advertise the current meter reading at the sending node.

  If either the `:rate_type` or `:delta_time` param is present, the command will be
  encoded as version 5. If neither are present, it will be encoded as version 1.

  ## Params

    * `:meter_type` - the type of metering physical unit being reported (required)
    * `:scale` - the unit used (required)
    * `:value` - the value being reported (required)
    * `:rate_type` - the type of rate being reported (optional)
    * `:previous_value` - the previous reported value (optional)
    * `:delta_time` - the time between the previous report and the current report (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Encoding}
  alias Grizzly.ZWave.CommandClasses.Meter

  @type meter_type :: :electric | :gas | :water | :heating | :cooling
  @type meter_scale :: atom()
  @type rate_type :: :default | :import | :export
  @type param ::
          {:meter_type, meter_type()}
          | {:scale, meter_scale()}
          | {:value, number()}
          | {:rate_type, rate_type()}
          | {:delta_time, number()}
          | {:previous_value, number() | :unknown}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :meter_report,
      command_byte: 0x02,
      command_class: Meter,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    if Command.has_param?(command, :rate_type) || Command.has_param?(command, :delta_time) do
      do_encode_params(:v5, command)
    else
      do_encode_params(:v1, command)
    end
  end

  defp do_encode_params(:v1, command) do
    meter_type = Command.param!(command, :meter_type)
    scale = Command.param!(command, :scale)
    value = Command.param!(command, :value)

    meter_type_bin = Meter.encode_meter_type(meter_type)
    {scale, _} = Meter.encode_meter_scale(scale, meter_type)

    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<0::3, meter_type_bin::5, precision::3, scale::2, byte_size::3,
      int_value::size(byte_size)-unit(8)>>
  end

  defp do_encode_params(_, command) do
    meter_type = Command.param!(command, :meter_type)
    scale = Command.param!(command, :scale)
    value = Command.param!(command, :value)

    meter_type_bin = Meter.encode_meter_type(meter_type)
    {scale1, scale2} = Meter.encode_meter_scale(scale, meter_type)

    rate_type = Command.param(command, :rate_type, :default)
    delta_time = Command.param(command, :delta_time, 0)
    previous_value = Command.param(command, :previous_value, 0)

    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<_::5, scale1_msb::1, scale1_rest::2>> = <<scale1>>

    previous_value_bin =
      cond do
        delta_time == 0 ->
          <<>>

        is_integer(previous_value) ->
          <<previous_value::size(byte_size)-unit(8)>>

        is_float(previous_value) ->
          v = round(previous_value * :math.pow(10, precision))
          <<v::size(byte_size)-unit(8)>>

        true ->
          <<0::size(byte_size)-unit(8)>>
      end

    delta_time =
      case delta_time do
        :unknown -> 0xFFFF
        _ -> delta_time
      end

    <<scale1_msb::1, Meter.encode_rate_type(rate_type)::2, meter_type_bin::5, precision::3,
      scale1_rest::2, byte_size::3, int_value::size(byte_size)-unit(8), delta_time::16,
      previous_value_bin::binary, scale2::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # v1
  def decode_params(
        <<0::3, meter_type_byte::5, precision::3, scale_byte::2, size::3,
          int_value::size(size)-unit(8)>>
      ) do
    with {:ok, meter_type} <- Meter.decode_meter_type(meter_type_byte),
         {:ok, scale} <- Meter.decode_meter_scale({scale_byte, 0}, meter_type) do
      value = Encoding.decode_zwave_float(int_value, precision)

      {:ok,
       [
         meter_type: meter_type,
         scale: scale,
         value: value,
         rate_type: nil,
         delta_time: nil,
         previous_value: nil
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # v2-v5
  def decode_params(
        <<scale1_msb::1, rate_type_bin::2, meter_type_bin::5, precision::3, scale1_rest::2,
          size::3, int_value::size(size)-unit(8), delta_time::16, rest::binary>>
      ) do
    <<scale1>> = <<0::5, scale1_msb::1, scale1_rest::2>>
    value = Encoding.decode_zwave_float(int_value, precision)

    with {:ok, meter_type} <- Meter.decode_meter_type(meter_type_bin),
         {:ok, rate_type} <- Meter.decode_rate_type(rate_type_bin),
         {:ok, {prev, scale2}} <- decode_rest(delta_time, size, precision, rest),
         {:ok, scale} <- Meter.decode_meter_scale({scale1, scale2}, meter_type) do
      {:ok,
       [
         meter_type: meter_type,
         scale: scale,
         value: value,
         rate_type: rate_type,
         delta_time: delta_time,
         previous_value: prev
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # decodes the optional previous value field and scale2 field (which is only present
  # in v4-5)
  defp decode_rest(delta_time, size, precision, rest) do
    case {delta_time, rest} do
      {0, <<>>} ->
        {:ok, {:unknown, 0}}

      {0, <<scale2::8>>} ->
        {:ok, {:unknown, scale2}}

      {_, <<previous_value::size(size)-unit(8)>>} ->
        {:ok, {Encoding.decode_zwave_float(previous_value, precision), 0}}

      {_, <<previous_value::size(size)-unit(8), scale2::8>>} ->
        {:ok, {Encoding.decode_zwave_float(previous_value, precision), scale2}}

      _ ->
        {:error,
         %DecodeError{value: rest, param: :previous_value_or_scale2, command: :meter_report}}
    end
  end
end
