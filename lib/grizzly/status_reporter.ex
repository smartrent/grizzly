defmodule Grizzly.StatusReporter do
  @moduledoc """
  A behaviour that is used to report the status of various parts of the Grizzly
  runtime
  """

  alias Grizzly.FirmwareUpdates.OTWUpdateRunner

  @type serial_api_status :: :ok | :unresponsive

  @doc """
  This callback is called when Grizzly starts up zipgateway and able to
  establish everything is running correctly.

  After this callback is called the implementor can assume the it is safe to
  access the Z-Wave network through Grizzly.
  """
  @doc deprecated: "Use `Grizzly.Events` instead"
  @callback ready() :: any()

  @doc """
  This callback is executed during a firmware update of the Z-Wave module
  """
  @doc deprecated: "Use `Grizzly.Events` instead"
  @callback zwave_firmware_update_status(OTWUpdateRunner.update_status()) :: any()

  @doc """
  Called when the Serial API status changes. Only applicable if Grizzly is managing
  the Z/IP Gateway process.
  """
  @doc deprecated: "Use `Grizzly.Events` instead"
  @callback serial_api_status(serial_api_status()) :: any()

  @optional_callbacks [serial_api_status: 1]
end
