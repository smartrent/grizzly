defmodule Grizzly.FirmwareUpdateHandler do
  @moduledoc """
  Behaviour for handling incoming commands during the firmware update process

  When you initialize a firmware update process you can pass the `:handler` option
  to the function which can either be the a `pid` (defaults to caller pid) or a
  module that implements this behaviour.

  The report this callback function will most want to handle is:

  - `Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport` It indicates whether the formware update was initiated successfully.
  - `Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport` It is sent by the target device once the firmware update completes, successfully or in failure.

  The callback might also want to be aware of:

  - `Grizzly.ZWave.Commands.FirmwareUpdateMDGet` It is sent by the target device when it wants more firmware image fragments
  - `Grizzly.ZWave.Commands.FirmwareMDReport` It might be sent by the target device during the upgrade to modify the maximum fragment size.
  - `Grizzly.ZWave.Commands.FirmwareUpdateActivationReport` It is sent by the target device in response to an activation request and gives the activation status.

  """

  alias Grizzly.ZWave.Command

  @callback handle_command(Command.t(), keyword()) :: :ok
end
