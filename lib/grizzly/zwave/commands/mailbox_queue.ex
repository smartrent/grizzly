defmodule Grizzly.ZWave.Commands.MailboxQueue do
  @moduledoc """
  The Mailbox Queue Command is a container for various operations between a
  mailbox proxy and a Mailbox Service.

  Params:

  * `last` - Indicates if this is the last command in the queue. Only applies when
    the operation is `:pop`.
  * `operation` - The operation to perform.
  * `handle` - Used along with the message's source IP address to identify the
    queue the message belongs to.
  * `entry` - The message to be operated upon.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @type operation :: :push | :pop | :waiting | :ping | :ack | :nack | :queue_full

  @type param ::
          {:last, boolean()} | {:operation, operation()} | {:handle, byte()} | {:entry, binary()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_queue,
      command_byte: 0x04,
      command_class: Mailbox,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    last = Command.param(command, :last, false)
    operation = Command.param!(command, :operation)
    handle = Command.param!(command, :handle)
    entry = Command.param!(command, :entry)

    <<0::4, bool_to_bit(last)::1, encode_operation(operation)::3, handle::8>> <> entry
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_reserved::4, last::1, operation::3, handle::8, entry::binary>>) do
    {:ok,
     [
       last: bit_to_bool(last),
       operation: decode_operation(operation),
       handle: handle,
       entry: entry
     ]}
  end

  defp encode_operation(:push), do: 0
  defp encode_operation(:pop), do: 1
  defp encode_operation(:waiting), do: 2
  defp encode_operation(:ping), do: 3
  defp encode_operation(:ack), do: 4
  defp encode_operation(:nack), do: 5
  defp encode_operation(:queue_full), do: 6

  defp decode_operation(0), do: :push
  defp decode_operation(1), do: :pop
  defp decode_operation(2), do: :waiting
  defp decode_operation(3), do: :ping
  defp decode_operation(4), do: :ack
  defp decode_operation(5), do: :nack
  defp decode_operation(6), do: :queue_full
end
