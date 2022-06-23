defmodule Grizzly.VirtualDevices.Device do
  @moduledoc """
  Behaviour for implementing virtual device specifics
  """

  alias Grizzly.ZWave.{Command, DeviceClass}

  @typedoc """
  A module that implements this behaviour
  """
  @type t() :: module()

  @typedoc """
  Optional device options that are passed with calling implemented callbacks

  This can be whatever extra information the consumer might need the device to
  know about when executing the callback function.
  """
  @type device_opt() :: {atom(), term()}

  @doc """
  Return the device specification
  """
  @callback device_spec([device_opt()]) :: DeviceClass.t()

  @doc """
  Handle a Z-Wave command

  When handling a command you can reply, notify, or do nothing.

  In Z-Wave if your device does not understand the command sent it ignores the
  command. For this case you'd return `{:error, :timeout}`.

  When a command is received and your device supports the command and the
  command's parameters, you either respond with `:ok` or `{:ok, Command.t()}`.
  Normally, when you receive a "set" command you will want to response with
  `:ok`. When you receive a "get" command you will want to response the report
  command like `{:ok, Command.t()}`, where the `Command.t()` is whatever command
  report you want to send to the caller.

  Often times, if your device reports changes that have been made due to
  handling a command, you can return `{:notify, Command.t()}`.
  """
  @callback handle_command(Command.t(), [device_opt()]) ::
              :ok | {:ok, Command.t()} | {:notify, Command.t()} | {:error, :timeout}
end
