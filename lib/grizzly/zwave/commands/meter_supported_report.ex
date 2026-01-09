defmodule Grizzly.ZWave.Commands.MeterSupportedReport do
  @moduledoc """
  This module implement command METER_SUPPORTED_REPORT of command class METER.

  This command is used to advertise the supported scales and metering capabilities of the sending node.

  ## Parameters

  * `:meter_reset_supported` - whether the node supports the METER_RESET command (required)
  * `:meter_type` - the implemented meter type (required)
  * `:supported_scales` - the supported scales (required)
  * `:rate_type` - the supported rate type (v4+)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Meter
  alias Grizzly.ZWave.DecodeError

  @type param :: {:meter_reset, any()} | {:meter_type, any()} | {:scale_supported, any()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    meter_reset_supported_bit =
      if Command.param!(command, :meter_reset_supported) == true, do: 1, else: 0

    meter_type = Command.param!(command, :meter_type)
    meter_type_bin = Meter.encode_meter_type(meter_type)
    supported_scales = Command.param!(command, :supported_scales)

    rate_type_bin =
      case Command.param(command, :rate_type) do
        nil -> 0
        rate_type -> Meter.encode_rate_type(rate_type)
      end

    {scales_bitmask1, scales_bitmask2} =
      Meter.encode_supported_scales_bitmasks(supported_scales, meter_type)

    if scales_bitmask2 == 0 do
      <<meter_reset_supported_bit::1, rate_type_bin::2, meter_type_bin::5, scales_bitmask1>>
    else
      <<meter_reset_supported_bit::1, rate_type_bin::2, meter_type_bin::5, 1::1,
        scales_bitmask1::7, 1, scales_bitmask2>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<meter_reset_supported_bit::1, rate_type_bin::2, meter_type_bin::5, scales_bitmask1::8>>
      ) do
    with {:ok, rate_type} <- Meter.decode_rate_type(rate_type_bin),
         {:ok, meter_type} <- Meter.decode_meter_type(meter_type_bin),
         {:ok, supported_scales} =
           Meter.decode_supported_scales_bitmasks({<<scales_bitmask1>>, <<0>>}, meter_type) do
      meter_reset_supported = meter_reset_supported_bit == 1

      {:ok,
       [
         meter_reset_supported: meter_reset_supported,
         meter_type: meter_type,
         rate_type: rate_type,
         supported_scales: supported_scales
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def decode_params(
        <<meter_reset_supported_bit::1, rate_type_bin::2, meter_type_bin::5, 1::1,
          scales_bitmask1::7, 1, scales_bitmask2::binary>>
      ) do
    with {:ok, rate_type} <- Meter.decode_rate_type(rate_type_bin),
         {:ok, meter_type} <- Meter.decode_meter_type(meter_type_bin),
         {:ok, supported_scales} =
           Meter.decode_supported_scales_bitmasks(
             {<<scales_bitmask1>>, scales_bitmask2},
             meter_type
           ) do
      meter_reset_supported = meter_reset_supported_bit == 1

      {:ok,
       [
         meter_reset_supported: meter_reset_supported,
         meter_type: meter_type,
         rate_type: rate_type,
         supported_scales: supported_scales
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
