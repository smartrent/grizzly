defmodule Grizzly.CommandClass.Meter do
  @type meter_report :: %{
          scale: integer,
          rate_type: integer,
          meter_type: integer,
          precision: integer,
          reading: integer
        }

  # Define command-specific encodings here
end
