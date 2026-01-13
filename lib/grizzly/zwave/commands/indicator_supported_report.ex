defmodule Grizzly.ZWave.Commands.IndicatorSupportedReport do
  @moduledoc """
  This command is used to advertise the supported properties for a given indicator.

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required)

    * `:next_indicator_id` - This field is used to advertise if more Indicator IDs are supported after the actual Indicator ID advertised
                              by the Indicator ID field. (optional)

    * `:property_ids` - The ids of the supported properties by the resource (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Indicator
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:indicator_id, Indicator.indicator_id()}
          | {:next__indicator_id, Indicator.indicator_id()}
          | {:property_ids, [Indicator.property_id()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    indicator_id_byte = Command.param!(command, :indicator_id) |> Indicator.indicator_id_to_byte()

    next_indicator_id_byte =
      Command.param(command, :next_indicator_id, 0x00) |> Indicator.indicator_id_to_byte()

    property_ids = Command.param!(command, :property_ids)
    masks = encode_property_ids(property_ids)
    count = Enum.count(masks)
    masks_binary = for mask <- masks, into: <<>>, do: mask
    <<indicator_id_byte, next_indicator_id_byte, 0x00::3, count::5>> <> masks_binary
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<indicator_id_byte, next_indicator_id_byte, 0x00::3, _count::5,
          property_id_masks::binary>>
      ) do
    with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte),
         {:ok, next_indicator_id} <- Indicator.indicator_id_from_byte(next_indicator_id_byte),
         {:ok, property_ids} <- decode_property_ids(property_id_masks) do
      {:ok,
       [
         indicator_id: indicator_id,
         next_indicator_id: next_indicator_id,
         property_ids: property_ids
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :indicator_supported_report}}
    end
  end

  defp encode_property_ids(property_ids) do
    bytes = Enum.map(property_ids, &Indicator.property_id_to_byte(&1))
    max_byte = Enum.max(bytes)

    bits =
      for i <- 0..max_byte do
        if i in bytes, do: 1, else: 0
      end

    for chunk <- Enum.chunk_every(bits, 8, 8, [0, 0, 0, 0, 0, 0, 0]) do
      bits = Enum.reverse(chunk)
      for bit <- bits, into: <<>>, do: <<bit::1>>
    end
  end

  defp decode_property_ids(property_id_masks) do
    :binary.bin_to_list(property_id_masks)
    |> Enum.with_index()
    |> Enum.reduce_while(
      {:ok, []},
      fn {mask, offset}, {:ok, acc} ->
        case decode_mask(<<mask>>, offset * 8) do
          {:ok, property_ids} -> {:cont, {:ok, property_ids ++ acc}}
          {:error, %DecodeError{}} = error -> {:halt, error}
        end
      end
    )
  end

  defp decode_mask(mask, offset) do
    indexed_bits =
      for(<<bit::1 <- mask>>, do: bit) |> Enum.reverse() |> Enum.with_index(offset)

    Enum.reduce_while(
      indexed_bits,
      {:ok, []},
      fn {bit, index}, {:ok, acc} ->
        if bit == 1 do
          case Indicator.property_id_from_byte(index) do
            {:ok, property_id} ->
              {:cont, {:ok, [property_id | acc]}}

            {:error, %DecodeError{} = decode_error} ->
              {:halt, {:error, %DecodeError{decode_error | command: :indicator_supported_report}}}
          end
        else
          {:cont, {:ok, acc}}
        end
      end
    )
  end
end
