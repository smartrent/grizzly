defmodule Grizzly.ZWave.Commands.MailboxWakeUpNotification do
  @moduledoc """
  The Mailbox Wake Up Notification command is used to notify the mailbox service
  that a wake up device is currently awake.

  Params:

  * `handle` - The handle of the queue that should be notified.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @type param :: {:handle, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_wake_up_notification,
      command_byte: 0x05,
      command_class: Mailbox,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    handle = Command.param!(command, :handle)
    <<handle::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<handle::8>>) do
    {:ok, [handle: handle]}
  end
end
