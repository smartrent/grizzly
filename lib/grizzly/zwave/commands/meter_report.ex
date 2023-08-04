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
  @type rate_type :: :unspecified | :import | :export
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

    meter_type_bin = encode_meter_type(meter_type)
    {scale, _} = encode_meter_scale(scale, meter_type)

    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<0::3, meter_type_bin::5, precision::3, scale::2, byte_size::3,
      int_value::size(byte_size)-unit(8)>>
  end

  defp do_encode_params(_, command) do
    meter_type = Command.param!(command, :meter_type)
    scale = Command.param!(command, :scale)
    value = Command.param!(command, :value)

    meter_type_bin = encode_meter_type(meter_type)
    {scale1, scale2} = encode_meter_scale(scale, meter_type)

    rate_type = Command.param(command, :rate_type, :unspecified)
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

    <<scale1_msb::1, encode_rate_type(rate_type)::2, meter_type_bin::5, precision::3,
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
    with {:ok, meter_type} <- decode_meter_type(meter_type_byte),
         {:ok, scale} <- decode_meter_scale({scale_byte, nil}, meter_type) do
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

    with {:ok, meter_type} <- decode_meter_type(meter_type_bin),
         {:ok, rate_type} <- decode_rate_type(rate_type_bin),
         {:ok, {prev, scale2}} <- decode_rest(delta_time, size, precision, rest),
         {:ok, scale} <- decode_meter_scale({scale1, scale2}, meter_type) do
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

  defp encode_meter_type(:electric), do: 0x01
  defp encode_meter_type(:gas), do: 0x02
  defp encode_meter_type(:water), do: 0x03
  defp encode_meter_type(:heating), do: 0x04
  defp encode_meter_type(:cooling), do: 0x05

  defp decode_meter_type(0x01), do: {:ok, :electric}
  defp decode_meter_type(0x02), do: {:ok, :gas}
  defp decode_meter_type(0x03), do: {:ok, :water}
  defp decode_meter_type(0x04), do: {:ok, :heating}
  defp decode_meter_type(0x05), do: {:ok, :cooling}

  defp decode_meter_type(byte),
    do: {:error, %DecodeError{value: byte, param: :meter_type, command: :meter_report}}

  defp encode_meter_scale(:kwh, :electric), do: {0x00, 0x00}
  defp encode_meter_scale(:kvah, :electric), do: {0x01, 0x00}
  defp encode_meter_scale(:w, :electric), do: {0x02, 0x00}
  defp encode_meter_scale(:pulse_count, :electric), do: {0x03, 0x00}
  defp encode_meter_scale(:v, :electric), do: {0x04, 0x00}
  defp encode_meter_scale(:a, :electric), do: {0x05, 0x00}
  defp encode_meter_scale(:power_factor, :electric), do: {0x06, 0x00}
  defp encode_meter_scale(:kvar, :electric), do: {0x07, 0x00}
  defp encode_meter_scale(:kvarh, :electric), do: {0x07, 0x01}

  defp encode_meter_scale(:cubic_meters, :gas), do: {0x00, 0x00}
  defp encode_meter_scale(:cubic_feet, :gas), do: {0x01, 0x00}
  defp encode_meter_scale(:pulse_count, :gas), do: {0x03, 0x00}

  defp encode_meter_scale(:cubic_meters, :water), do: {0x00, 0x00}
  defp encode_meter_scale(:cubic_feet, :water), do: {0x01, 0x00}
  defp encode_meter_scale(:us_gallons, :water), do: {0x02, 0x00}
  defp encode_meter_scale(:pulse_count, :water), do: {0x03, 0x00}

  defp encode_meter_scale(:kwh, :heating), do: {0x00, 0x00}
  defp encode_meter_scale(:kwh, :cooling), do: {0x00, 0x00}

  defp decode_meter_scale({0x00, _}, :electric), do: {:ok, :kwh}
  defp decode_meter_scale({0x01, _}, :electric), do: {:ok, :kvah}
  defp decode_meter_scale({0x02, _}, :electric), do: {:ok, :w}
  defp decode_meter_scale({0x03, _}, :electric), do: {:ok, :pulse_count}
  defp decode_meter_scale({0x04, _}, :electric), do: {:ok, :v}
  defp decode_meter_scale({0x05, _}, :electric), do: {:ok, :a}
  defp decode_meter_scale({0x06, _}, :electric), do: {:ok, :power_factor}
  defp decode_meter_scale({0x07, 0x00}, :electric), do: {:ok, :kvar}
  defp decode_meter_scale({0x07, 0x01}, :electric), do: {:ok, :kvarh}

  defp decode_meter_scale({0x00, _}, :gas), do: {:ok, :cubic_meters}
  defp decode_meter_scale({0x01, _}, :gas), do: {:ok, :cubic_feet}
  defp decode_meter_scale({0x03, _}, :gas), do: {:ok, :pulse_count}

  defp decode_meter_scale({0x00, _}, :water), do: {:ok, :cubic_meters}
  defp decode_meter_scale({0x01, _}, :water), do: {:ok, :cubic_feet}
  defp decode_meter_scale({0x02, _}, :water), do: {:ok, :us_gallons}
  defp decode_meter_scale({0x03, _}, :water), do: {:ok, :pulse_count}

  defp decode_meter_scale({0x00, _}, :heating), do: {:ok, :kwh}
  defp decode_meter_scale({0x00, _}, :cooling), do: {:ok, :kwh}

  defp decode_meter_scale(byte, type),
    do: {:error, %DecodeError{value: {byte, type}, param: :meter_scale, command: :meter_report}}

  defp encode_rate_type(:unspecified), do: 0x00
  defp encode_rate_type(:import), do: 0x01
  defp encode_rate_type(:export), do: 0x02

  defp decode_rate_type(0x00), do: {:ok, :unspecified}
  defp decode_rate_type(0x01), do: {:ok, :import}
  defp decode_rate_type(0x02), do: {:ok, :export}

  defp decode_rate_type(v),
    do: {:error, %DecodeError{value: v, param: :rate_type, command: :meter_report}}
end
