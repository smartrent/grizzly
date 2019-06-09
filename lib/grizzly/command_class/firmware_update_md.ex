defmodule Grizzly.CommandClass.FirmwareUpdateMD do
  @type report :: %{
          manufacturer_id: non_neg_integer,
          firmware_id: non_neg_integer,
          checksum: binary
        }
end
