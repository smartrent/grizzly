defmodule Grizzly.CommandClass.TimeParameters do
  @moduledoc false

  @type date_time :: %{
          year: integer,
          month: integer,
          day: integer,
          hour: integer,
          minute: integer,
          second: integer
        }

  # Define command-specific encodings here
end
