defmodule Grizzly.ZWave.CommandClasses.ScheduleEntryLock do
  @moduledoc """
  "ScheduleEntryLock" Command Class

  The Schedule Entry Lock Command Class provides Z-Wave devices the capability to exchange scheduling information.
  """

  @type week_day ::
          :saturday
          | :friday
          | :thursday
          | :wednesday
          | :tuesday
          | :monday
          | :sunday

  @weekdays [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  def weekdays_to_bitmask(active_days) do
    active_day_indices =
      for week_day <- active_days, do: Enum.find_index(@weekdays, fn day -> day == week_day end)

    <<bitmask::7>> =
      for day_index <- 6..0//-1, into: <<>> do
        if day_index in active_day_indices, do: <<0x01::1>>, else: <<0x00::1>>
      end

    <<0::1, bitmask::7>>
  end

  def bitmask_to_weekdays(byte) do
    find_indices_of_bits(byte)
    |> Enum.map(fn index -> Enum.at(@weekdays, index) end)
  end

  def find_indices_of_bits(byte) do
    bitmask = <<byte>>

    for(<<x::1 <- bitmask>>, do: x)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce([], fn {bit, index}, acc ->
      if bit == 1, do: [index | acc], else: acc
    end)
  end

  def encode_set_action(:erase), do: 0
  def encode_set_action(:modify), do: 1
  def decode_set_action(0), do: :erase
  def decode_set_action(1), do: :modify
  def decode_set_action(_), do: :unknown
end
