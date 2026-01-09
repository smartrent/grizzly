defmodule Grizzly.ZWave.Commands.TimeOffsetSetReport do
  @moduledoc """
  This command is used to set Time Zone Offset (TZO) and Daylight Savings Time (DST) at the supporting
  node.

  Params:

    * `:sign_tzo` - This field is used to indicate the sign (:plus or :minus) to apply to the Hour TZO and Minute TZO fields. (required)

    * `:hour_tzo` - This field is used to indicate the number of hours that the originating time zone deviates from UTC. (required - 0..14)

    * `:minute_tzo` - This field is used to indicate the number of minutes that the originating time zone deviates from UTC. (required - 0..59)

    * `:sign_offset_dst` - This field is used to indicate the sign (:plus or :minus) for the Minute Offset DST field to apply to the
                          current time while in the Daylight Saving Time. (required)

    * `:minute_offset_dst` - This field MUST indicate the number of minutes by which the current time is to be adjusted when
                             Daylight Saving Time starts. (required - 0..59)

    * `:month_start_dst` - This field MUST indicate the month of the year when Daylight Saving Time starts. (required, 1..12)

    * `:day_start_dst` - This field MUST indicate the day of the month when Daylight Saving Time starts. (required - 1..31)

    * `:hour_start_dst` - This field MUST indicate the hour of the day when Daylight Saving Time starts. (required - 0..23)

    * `:month_end_dst` - This field MUST indicate the month of the year when Daylight Saving Time ends. (required, 1..12)

    * `:day_end_dst` - This field MUST indicate the day of the month when Daylight Saving Time ends. (required - 1..31)

    * `:hour_end_dst` - This field MUST indicate the hour of the day when Daylight Saving Time ends. (required - 0..23)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type sign :: :plus | :minus
  @type param ::
          {:sign_tzo, sign()}
          | {:hour_tzo, 0..23}
          | {:minute_tzo, 0..59}
          | {:sign_offset_dst, sign()}
          | {:minute_offset_dst, byte}
          | {:month_start_dst, 1..12}
          | {:day_start_dst, 1..31}
          | {:hour_start_dst, 0..59}
          | {:month_end_dst, 1..12}
          | {:day_end_dst, 1..31}
          | {:hour_end_dst, 0..59}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sign_tzo = Command.param!(command, :sign_tzo)
    hour_tzo = Command.param!(command, :hour_tzo)
    minute_tzo = Command.param!(command, :minute_tzo)
    sign_offset_dst = Command.param!(command, :sign_offset_dst)
    minute_offset_dst = Command.param!(command, :minute_offset_dst)
    month_start_dst = Command.param!(command, :month_start_dst)
    day_start_dst = Command.param!(command, :day_start_dst)
    hour_start_dst = Command.param!(command, :hour_start_dst)
    month_end_dst = Command.param!(command, :month_end_dst)
    day_end_dst = Command.param!(command, :day_end_dst)
    hour_end_dst = Command.param!(command, :hour_end_dst)

    <<encode_sign(sign_tzo)::size(1), hour_tzo::7, minute_tzo,
      encode_sign(sign_offset_dst)::size(1), minute_offset_dst::7, month_start_dst, day_start_dst,
      hour_start_dst, month_end_dst, day_end_dst, hour_end_dst>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<sign_tzo_bit::1, hour_tzo::7, minute_tzo, sign_offset_dst_bit::1, minute_offset_dst::7,
          month_start_dst, day_start_dst, hour_start_dst, month_end_dst, day_end_dst,
          hour_end_dst>>
      ) do
    {:ok,
     [
       sign_tzo: decode_sign(sign_tzo_bit),
       hour_tzo: hour_tzo,
       minute_tzo: minute_tzo,
       sign_offset_dst: decode_sign(sign_offset_dst_bit),
       minute_offset_dst: minute_offset_dst,
       month_start_dst: month_start_dst,
       day_start_dst: day_start_dst,
       hour_start_dst: hour_start_dst,
       month_end_dst: month_end_dst,
       day_end_dst: day_end_dst,
       hour_end_dst: hour_end_dst
     ]}
  end

  defp encode_sign(:plus), do: 0
  defp encode_sign(:minus), do: 1

  defp decode_sign(0), do: :plus
  defp decode_sign(1), do: :minus
end
