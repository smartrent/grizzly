defmodule Grizzly.ZWave.Commands.MeterGet do
  @moduledoc """
  This module implements the METER_GET command of the COMMAND_CLASS_METER command class.

  This command is used to request the current meter reading to a supporting node.

  Params: - none - (v1)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Meter

  @type param ::
          {:scale, Meter.meter_scale() | 0..7}
          | {:rate_type, Meter.meter_rate_type()}
          | {:scale2, byte()}

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :meter_get,
      command_byte: 0x01,
      command_class: Meter,
      impl: __MODULE__,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    cond do
      Command.has_param?(command, :scale2) -> encode_v4_and_later_raw(command)
      Command.has_param?(command, :scale) -> encode_v2_and_later(command)
      true -> <<>>
    end
  end

  defp encode_v2_and_later(command) do
    scale = Command.param!(command, :scale)
    {scale1, scale2} = Meter.encode_meter_scale(scale)
    has_rate_type? = Command.param(command, :rate_type, nil) != nil

    if has_rate_type? or scale in [:kvar, :kvarh] or scale2 != 0 do
      # v4-6
      rate_type = Command.param(command, :rate_type, :default)
      rate_type_bin = Meter.encode_rate_type(rate_type)

      {scale1, scale2} = Meter.encode_meter_scale(scale)

      <<rate_type_bin::2, scale1::3, 0::3, scale2>>
    else
      # v2-3
      <<0::2, scale1::3, 0::3>>
    end
  end

  defp encode_v4_and_later_raw(command) do
    scale = Command.param!(command, :scale)
    scale2 = Command.param!(command, :scale2)
    rate_type = Command.param!(command, :rate_type)

    <<Meter.encode_rate_type(rate_type)::2, scale::3, 0::3, scale2>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(binary) do
    # Yikes... we don't know the meter type here, so we can't decode the scale properly.
    case binary do
      <<rate_type_bin::2, scale1::3, _::3, scale2>> ->
        {:ok, rate_type} = Meter.decode_rate_type(rate_type_bin)
        {:ok, [scale: scale1, scale2: scale2, rate_type: rate_type]}

      <<_::2, scale1::3, _::3>> ->
        {:ok, [scale: scale1, rate_type: nil]}

      <<>> ->
        {:ok, [scale: nil, rate_type: nil]}
    end
  end

  def decode_params(binary, meter_type) do
    {:ok, params} = decode_params(binary)

    if params[:scale] != nil do
      scale =
        case Meter.decode_meter_scale({params[:scale], params[:scale2]}, meter_type) do
          {:ok, scale} -> scale
          _ -> :unknown
        end

      {:ok, scale: scale, rate_type: params[:rate_type]}
    else
      {:ok, scale: nil, rate_type: params[:rate_type]}
    end
  end
end
