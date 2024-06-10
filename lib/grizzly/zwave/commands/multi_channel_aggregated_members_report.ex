defmodule Grizzly.ZWave.Commands.MultiChannelAggregatedMembersReport do
  @moduledoc """
  This command is used to advertise the members of an Aggregated End Point.

  Params:

    * `:aggregated_end_point` - an aggregated end_point (required)

    * `:members` - the lists of end points member of the aggregated end point (required, can be an empty list)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param ::
          {:aggregated_end_point, MultiChannel.end_point()}
          | {:members, [MultiChannel.end_point()]}

  @impl true
  def new(params) do
    command = %Command{
      name: :multi_channel_aggregated_members_report,
      command_byte: 0x0F,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    aggregated_end_point = Command.param!(command, :aggregated_end_point)
    members = Command.param!(command, :members)
    encoded_members = encode_members(members)
    count = byte_size(encoded_members)
    <<0x00::1, aggregated_end_point::7, count>> <> encoded_members
  end

  @impl true
  def decode_params(<<0x00::1, aggregated_end_point::7, count, bitmasks::binary-size(count)>>) do
    members = decode_members(bitmasks)
    {:ok, [aggregated_end_point: aggregated_end_point, members: members]}
  end

  defp encode_members(members) do
    masks_count = ceil(Enum.max(members) / 8)

    for i <- 0..(masks_count - 1), into: <<>> do
      start = i * 8 + 1

      for j <- (start + 7)..start, into: <<>> do
        if j in members, do: <<0x01::1>>, else: <<0x00::1>>
      end
    end
  end

  defp decode_members(bitmasks) do
    masks = for byte <- :erlang.binary_to_list(bitmasks), do: <<byte>>

    for i <- 0..(Enum.count(masks) - 1) do
      mask = Enum.at(masks, i)
      indexed_bits = for(<<x::1 <- mask>>, do: x) |> Enum.reverse() |> Enum.with_index(1)
      start = i * 8

      Enum.reduce(indexed_bits, [], fn {bit, index}, acc ->
        if bit == 1, do: [index + start | acc], else: acc
      end)
    end
    |> List.flatten()
    |> Enum.sort()
  end
end
