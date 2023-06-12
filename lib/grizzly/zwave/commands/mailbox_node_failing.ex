defmodule Grizzly.ZWave.Commands.MailboxNodeFailing do
  @moduledoc """
  The Mailbox Node Failing command allows a mailbox proxy to notify a Mailbox
  Service that a wake up device is no longer available.

  Params:
  * `handle` - The handle of the queue that should be discarded.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @type param :: {:handle, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_node_failing,
      command_byte: 0x06,
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

  # Z/IP Gateway sends the node's IPv6 address in the handle field because why not? :clown_face:
  def decode_params(<<_::16, _::16, _::16, _::16, _::16, _::16, _::16, handle::16>>) do
    {:ok, [handle: handle]}
  end
end
