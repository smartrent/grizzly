defmodule Grizzly.CommandClass.ScheduleEntryLock do
  @type enabled_value :: :enabled | :disabled
  @type enable_action :: :enable | :disable
  @type enabled_value_byte :: 0x00 | 0x01
  @type supported_report :: %{
          week_day_slots: non_neg_integer,
          year_day_slots: non_neg_integer,
          daily_repeating: non_neg_integer
        }
  @type weekday :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type weekdays :: [weekday]
  @type daily_repeating_report :: %{
          user_id: non_neg_integer,
          slot_id: non_neg_integer,
          week_days: weekdays(),
          start_hour: non_neg_integer,
          start_minute: non_neg_integer,
          duration_hour: non_neg_integer,
          duration_minute: non_neg_integer
        }

  @type year_day_report :: %{
          user_id: non_neg_integer,
          slot_id: non_neg_integer,
          start_year: non_neg_integer,
          start_month: non_neg_integer,
          start_day: non_neg_integer,
          start_hour: non_neg_integer,
          start_minute: non_neg_integer,
          stop_year: non_neg_integer,
          stop_month: non_neg_integer,
          stop_day: non_neg_integer,
          stop_hour: non_neg_integer,
          stop_minute: non_neg_integer
        }

  @spec encode_enabled_value(enabled_value) :: enabled_value_byte
  def encode_enabled_value(:enabled), do: 0x01
  def encode_enabled_value(:disabled), do: 0x00

  @spec encode_enable_action(enable_action) :: enabled_value_byte
  def encode_enable_action(:enable), do: 0x01
  def encode_enable_action(:disable), do: 0x00

  @spec encode_weekdays(weekdays()) :: binary()
  def encode_weekdays(weekdays) do
    days = [:saturday, :friday, :thursday, :wednesday, :tuesday, :monday, :sunday]

    bits =
      Enum.reduce(
        days,
        %{},
        fn day, acc ->
          if day in weekdays do
            Map.put(acc, day, 1)
          else
            Map.put(acc, day, 0)
          end
        end
      )

    <<
      0::size(1),
      Map.get(bits, :saturday)::size(1),
      Map.get(bits, :friday)::size(1),
      Map.get(bits, :thursday)::size(1),
      Map.get(bits, :wednesday)::size(1),
      Map.get(bits, :tuesday)::size(1),
      Map.get(bits, :monday)::size(1),
      Map.get(bits, :sunday)::size(1)
    >>
  end

  @spec decode_weekdays(byte) :: weekdays()
  def decode_weekdays(mask) do
    <<
      _reserved::size(1),
      sat::size(1),
      fri::size(1),
      thu::size(1),
      wed::size(1),
      tue::size(1),
      mon::size(1),
      sun::size(1)
    >> = <<mask::size(8)>>

    bits = [sat, fri, thu, wed, tue, mon, sun]
    days = [:saturday, :friday, :thursday, :wednesday, :tuesday, :monday, :sunday]

    Enum.zip(days, bits)
    |> Enum.reduce([], fn {day, bit}, acc -> if bit == 1, do: [day | acc], else: acc end)
  end

  @spec decode_year(non_neg_integer) :: non_neg_integer
  @doc "Given the last two digits of a year, return the year"
  def decode_year(decade) when decade in 0..99 do
    2000 + decade
  end

  def decode_year(_decade) do
    0
  end

  @spec encode_year(non_neg_integer) :: non_neg_integer
  @doc "Given a year, return the last two digits of it"
  def encode_year(year) when year in 2000..2099 do
    year - 2000
  end

  def encode_year(_year) do
    0
  end
end
