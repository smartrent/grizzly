defmodule Grizzly.CommandClass.Time do
  @moduledoc false

  @type time_report :: %{
          hour: integer,
          minute: integer,
          second: integer
        }

  @type date_report :: %{
          year: integer,
          month: integer,
          day: integer
        }

  @type offset :: %{
          # 0 is positive, 1 is negative to UTC
          sign_tzo: 0 | 1,
          # deviation from UTC
          hour_tzo: integer,
          minute_tzo: integer,
          sign_offset_dst: 0 | 1,
          minute_offset_dst: integer,
          # start of DST
          month_start_dst: integer,
          day_start_dst: integer,
          # end of DST
          hour_start_dst: integer,
          month_end_dst: integer,
          day_end_dst: integer,
          hour_end_dst: integer
        }

  # Define command-specific encodings here
end
