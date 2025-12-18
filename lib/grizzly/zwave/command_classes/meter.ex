defmodule Grizzly.ZWave.CommandClasses.Meter do
  @moduledoc """
  "Meter" Command Class

  The Meter Command Class is used to advertise instantaneous and accumulated numerical readings.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @type meter_type :: :electric | :gas | :water | :heating | :cooling
  @type meter_scale ::
          :a
          | :cubic_feet
          | :cubic_meters
          | :kvah
          | :kvar
          | :kvarh
          | :kwh
          | :power_factor
          | :pulse_count
          | :us_gallons
          | :v
          | :w

  @type meter_rate_type :: :export | :import | :import_export | :default

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x32

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :meter

  @doc """
  Encode meter type
  """
  @spec encode_meter_type(meter_type()) :: 1..5
  def encode_meter_type(:electric), do: 0x01
  def encode_meter_type(:gas), do: 0x02
  def encode_meter_type(:water), do: 0x03
  def encode_meter_type(:heating), do: 0x04
  def encode_meter_type(:cooling), do: 0x05

  @doc """
  Decode meter type
  """
  @spec decode_meter_type(non_neg_integer()) ::
          {:ok, meter_type()} | {:error, Grizzly.ZWave.DecodeError.t()}
  def decode_meter_type(0x01), do: {:ok, :electric}
  def decode_meter_type(0x02), do: {:ok, :gas}
  def decode_meter_type(0x03), do: {:ok, :water}
  def decode_meter_type(0x04), do: {:ok, :heating}
  def decode_meter_type(0x05), do: {:ok, :cooling}

  def decode_meter_type(byte),
    do: {:error, %DecodeError{value: byte, param: :meter_type, command: :meter_report}}

  @spec encode_meter_scale(meter_scale()) :: {0..7, 0..1}
  def encode_meter_scale(:kwh), do: {0x00, 0x00}
  def encode_meter_scale(:kvah), do: {0x01, 0x00}
  def encode_meter_scale(:w), do: {0x02, 0x00}
  def encode_meter_scale(:pulse_count), do: {0x03, 0x00}
  def encode_meter_scale(:v), do: {0x04, 0x00}
  def encode_meter_scale(:a), do: {0x05, 0x00}
  def encode_meter_scale(:power_factor), do: {0x06, 0x00}
  def encode_meter_scale(:kvar), do: {0x07, 0x00}
  def encode_meter_scale(:kvarh), do: {0x07, 0x01}
  def encode_meter_scale(:cubic_meters), do: {0x00, 0x00}
  def encode_meter_scale(:cubic_feet), do: {0x01, 0x00}
  def encode_meter_scale(:us_gallons), do: {0x02, 0x00}

  @spec encode_meter_scale(meter_scale(), meter_type()) :: {0..7, 0..1}
  def encode_meter_scale(:kwh, :electric), do: {0x00, 0x00}
  def encode_meter_scale(:kvah, :electric), do: {0x01, 0x00}
  def encode_meter_scale(:w, :electric), do: {0x02, 0x00}
  def encode_meter_scale(:pulse_count, :electric), do: {0x03, 0x00}
  def encode_meter_scale(:v, :electric), do: {0x04, 0x00}
  def encode_meter_scale(:a, :electric), do: {0x05, 0x00}
  def encode_meter_scale(:power_factor, :electric), do: {0x06, 0x00}
  def encode_meter_scale(:kvar, :electric), do: {0x07, 0x00}
  def encode_meter_scale(:kvarh, :electric), do: {0x07, 0x01}

  def encode_meter_scale(:cubic_meters, :gas), do: {0x00, 0x00}
  def encode_meter_scale(:cubic_feet, :gas), do: {0x01, 0x00}
  def encode_meter_scale(:pulse_count, :gas), do: {0x03, 0x00}

  def encode_meter_scale(:cubic_meters, :water), do: {0x00, 0x00}
  def encode_meter_scale(:cubic_feet, :water), do: {0x01, 0x00}
  def encode_meter_scale(:us_gallons, :water), do: {0x02, 0x00}
  def encode_meter_scale(:pulse_count, :water), do: {0x03, 0x00}

  def encode_meter_scale(:kwh, :heating), do: {0x00, 0x00}
  def encode_meter_scale(:kwh, :cooling), do: {0x00, 0x00}

  @doc """
  Encode supported meter scales as two bit masks.
  The first bitmask encodes "byte 1" scales and the second bitmask encodes "byte 2" scales.
  We assume that there is no byte 3, 4, encoding etc.
  A bit 1 indicates support.
  """
  @spec encode_supported_scales_bitmasks([meter_scale()], meter_type()) :: {byte(), byte()}
  def encode_supported_scales_bitmasks(supported_scales, meter_type) do
    {byte_2_pairs, byte_1_pairs} =
      supported_scales
      |> Enum.map(&encode_meter_scale(&1, meter_type))
      |> Enum.split_with(fn {val1, _val2} -> val1 == 0x07 end)

    bitmask_1_indices = byte_1_pairs |> Enum.map(&elem(&1, 0))
    bitmask_2_indices = byte_2_pairs |> Enum.map(&elem(&1, 1))
    <<bitmask_1>> = Encoding.encode_bitmask(bitmask_1_indices)

    <<bitmask_2>> =
      if Enum.empty?(bitmask_2_indices),
        do: <<0>>,
        else: Encoding.encode_bitmask(bitmask_2_indices)

    {bitmask_1, bitmask_2}
  end

  @doc """
  Decode supported scales bitmasks.
  """
  @spec decode_supported_scales_bitmasks({binary(), binary()}, meter_type()) ::
          {:ok, [meter_scale()]}
  def decode_supported_scales_bitmasks({scales_bitmask1, scales_bitmask2}, meter_type) do
    bitmask_1_indices = Encoding.decode_bitmask(scales_bitmask1)

    bitmask_2_indices =
      if scales_bitmask2 == <<0>>,
        do: [],
        else: Encoding.decode_bitmask(scales_bitmask2)

    scales_1 =
      bitmask_1_indices
      |> Enum.reduce([], fn index, acc ->
        {:ok, scale} = decode_meter_scale({index, 0x00}, meter_type)
        [scale | acc]
      end)

    scales_2 =
      bitmask_2_indices
      |> Enum.reduce([], fn index, acc ->
        {:ok, scale} = decode_meter_scale({0x07, index}, meter_type)
        [scale | acc]
      end)

    {:ok, scales_1 ++ scales_2}
  end

  @doc """
  Decode meter scale
  """
  @spec decode_meter_scale({byte(), byte()}, meter_type() | non_neg_integer()) ::
          {:ok, meter_scale()} | {:error, DecodeError.t()}
  def decode_meter_scale({0x00, _}, :electric), do: {:ok, :kwh}
  def decode_meter_scale({0x01, _}, :electric), do: {:ok, :kvah}
  def decode_meter_scale({0x02, _}, :electric), do: {:ok, :w}
  def decode_meter_scale({0x03, _}, :electric), do: {:ok, :pulse_count}
  def decode_meter_scale({0x04, _}, :electric), do: {:ok, :v}
  def decode_meter_scale({0x05, _}, :electric), do: {:ok, :a}
  def decode_meter_scale({0x06, _}, :electric), do: {:ok, :power_factor}
  def decode_meter_scale({0x07, 0x00}, :electric), do: {:ok, :kvar}
  def decode_meter_scale({0x07, 0x01}, :electric), do: {:ok, :kvarh}

  def decode_meter_scale({0x00, _}, :gas), do: {:ok, :cubic_meters}
  def decode_meter_scale({0x01, _}, :gas), do: {:ok, :cubic_feet}
  def decode_meter_scale({0x03, _}, :gas), do: {:ok, :pulse_count}

  def decode_meter_scale({0x00, _}, :water), do: {:ok, :cubic_meters}
  def decode_meter_scale({0x01, _}, :water), do: {:ok, :cubic_feet}
  def decode_meter_scale({0x02, _}, :water), do: {:ok, :us_gallons}
  def decode_meter_scale({0x03, _}, :water), do: {:ok, :pulse_count}

  def decode_meter_scale({0x00, _}, :heating), do: {:ok, :kwh}
  def decode_meter_scale({0x00, _}, :cooling), do: {:ok, :kwh}

  def decode_meter_scale(byte, _type),
    do: {:error, %DecodeError{value: byte, param: :meter_scale, command: :meter_report}}

  @doc """
  Encode meter rate type
  """
  @spec encode_rate_type(meter_rate_type()) :: 0..3
  def encode_rate_type(:default), do: 0x00
  def encode_rate_type(:import), do: 0x01
  def encode_rate_type(:export), do: 0x02
  def encode_rate_type(:import_export), do: 0x03

  @doc """
  Decode rate type
  """
  @spec decode_rate_type(non_neg_integer()) ::
          {:ok, meter_rate_type()} | {:error, DecodeError.t()}
  def decode_rate_type(0x00), do: {:ok, :default}
  def decode_rate_type(0x01), do: {:ok, :import}
  def decode_rate_type(0x02), do: {:ok, :export}
  def decode_rate_type(0x03), do: {:ok, :import_export}

  def decode_rate_type(v),
    do: {:error, %DecodeError{value: v, param: :rate_type, command: :meter_report}}
end
