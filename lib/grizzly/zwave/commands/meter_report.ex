defmodule Grizzly.ZWave.Commands.MeterReport do
  @moduledoc """
  This module implements the command METER_REPORT of the COMMAND_CLASS_METER command class.

  This command is used to advertise the current meter reading at the sending node.

  Params:

    * `:meter_type` - the type of metering physical unit being reported (required)
    * `:scale` - the unit used (required)
    * `:value` - the value being reported (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Meter

  @type meter_type :: :electric | :gas | :water | :heating | :cooling
  @type meter_scale :: atom
  @type param ::
          {:meter_type, meter_type} | {:scale, meter_scale} | {:value, number}

  @impl true
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

  @impl true
  def encode_params(command) do
    meter_type = Command.param!(command, :meter_type)
    meter_type_byte = encode_meter_type(meter_type)
    scale_byte = encode_meter_scale(Command.param!(command, :scale), meter_type)
    value = Command.param!(command, :value)
    precision = precision(value)
    int_value = round(value * :math.pow(10, precision))
    byte_size = ceil(:math.log2(int_value) / 8)

    <<meter_type_byte, precision::size(3), scale_byte::size(2), byte_size::size(3),
      int_value::size(byte_size)-unit(8)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<meter_type_byte, precision::size(3), scale_byte::size(2), size::size(3),
          int_value::size(size)-unit(8), _::binary>>
      ) do
    with {:ok, meter_type} <- decode_meter_type(meter_type_byte),
         {:ok, scale} <- decode_meter_scale(scale_byte, meter_type) do
      value = int_value / :math.pow(10, precision)
      {:ok, [meter_type: meter_type, scale: scale, value: value]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp precision(value) when is_number(value) do
    case String.split("#{value}", ".") do
      [_] -> 0
      [_, dec] -> String.length(dec)
    end
  end

  defp encode_meter_type(:electric), do: 0x01
  defp encode_meter_type(:gas), do: 0x02
  defp encode_meter_type(:water), do: 0x03
  defp encode_meter_type(:heating), do: 0x04
  defp encode_meter_type(:cooling), do: 0x05

  defp encode_meter_scale(:kwh, :electric), do: 0x00
  defp encode_meter_scale(:kvah, :electric), do: 0x01
  defp encode_meter_scale(:w, :electric), do: 0x02
  defp encode_meter_scale(:pulse_count, :electric), do: 0x03
  defp encode_meter_scale(:v, :electric), do: 0x04
  defp encode_meter_scale(:a, :electric), do: 0x05
  defp encode_meter_scale(:power_factor, :electric), do: 0x06
  defp encode_meter_scale(:mst, :electric), do: 0x07
  defp encode_meter_scale(:cubic_meters, :gas), do: 0x00
  defp encode_meter_scale(:cubic_feet, :gas), do: 0x01
  defp encode_meter_scale(:pulse_count, :gas), do: 0x03
  defp encode_meter_scale(:mst, :gas), do: 0x07
  defp encode_meter_scale(:cubic_meters, :water), do: 0x00
  defp encode_meter_scale(:cubic_feet, :water), do: 0x00
  defp encode_meter_scale(:us_gallons, :water), do: 0x02
  defp encode_meter_scale(:pulse_count, :water), do: 0x03
  defp encode_meter_scale(:mst, :water), do: 0x07
  defp encode_meter_scale(:kwh, :heating), do: 0x00
  defp encode_meter_scale(:kwh, :cooling), do: 0x00

  defp decode_meter_type(0x01), do: {:ok, :electric}
  defp decode_meter_type(0x02), do: {:ok, :gas}
  defp decode_meter_type(0x03), do: {:ok, :water}
  defp decode_meter_type(0x04), do: {:ok, :heating}
  defp decode_meter_type(0x05), do: {:ok, :cooling}

  defp decode_meter_type(byte),
    do: {:error, %DecodeError{value: byte, param: :meter_type, command: :meter_report}}

  defp decode_meter_scale(0x00, :electric), do: {:ok, :kwh}
  defp decode_meter_scale(0x01, :electric), do: {:ok, :kvah}
  defp decode_meter_scale(0x02, :electric), do: {:ok, :w}
  defp decode_meter_scale(0x03, :electric), do: {:ok, :pulse_count}
  # defp decode_meter_scale(0x04, :electric), do: {:ok,:v }
  # defp decode_meter_scale(0x05, :electric), do: {:ok, :a}
  # defp decode_meter_scale(0x06, :electric), do: {:ok,:power_factor }
  # defp decode_meter_scale(0x07, :electric), do: {:ok, :mst}
  defp decode_meter_scale(0x00, :gas), do: {:ok, :cubic_meters}
  defp decode_meter_scale(0x01, :gas), do: {:ok, :cubic_feet}
  defp decode_meter_scale(0x03, :gas), do: {:ok, :pulse_count}
  # defp decode_meter_scale(0x07, :gas), do: {:ok, :mst}
  defp decode_meter_scale(0x00, :water), do: {:ok, :cubic_meters}
  defp decode_meter_scale(0x01, :water), do: {:ok, :cubic_feet}
  defp decode_meter_scale(0x02, :water), do: {:ok, :us_gallons}
  defp decode_meter_scale(0x03, :water), do: {:ok, :pulse_count}
  # defp decode_meter_scale(0x07, :water), do: {:ok, :mst}
  defp decode_meter_scale(0x00, :heating), do: {:ok, :kwh}
  defp decode_meter_scale(0x00, :cooling), do: {:ok, :kwh}

  defp decode_meter_scale(byte, _),
    do: {:error, %DecodeError{value: byte, param: :meter_type, command: :meter_scale}}
end
