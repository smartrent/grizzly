defmodule Grizzly.StatusReporter do
  @moduledoc """
  A behaviour that is used to report the status of various parts of the Grizzly
  runtime
  """

  @typedoc """
  The various status of a firmware update of the Z-Wave module

  * `:started` - the firmware update has been initiated and all validation of
    the firmware update is complete.
  * `:skipped` - the Z-Wave firmware on the module cannot be updated with any
    known firmware.
  * `:success` - the firmware update of the Z-Wave module is successful.
  * `{:error, reason}` - A firmware update of the Z-Wave module was attempted
    but failed for some `reason`.
  """
  @type zwave_firmware_status() :: :started | :skipped | :success | {:error, any()}

  @doc """
  This callback is called when Grizzly starts up zipgateway and able to
  establish everything is running correctly.

  After this callback is called the implementor can assume the it is safe to
  access the Z-Wave network through Grizzly.
  """
  @callback ready() :: :ok

  @doc """
  This callback is executed during a firmware update of the Z-Wave module
  """
  @callback zwave_firmware_update_status(zwave_firmware_status()) :: :ok
end
