defmodule Grizzly.ZWave.Commands.S2NonceReport do
  @moduledoc """
  What does this command do??

  ## Params

  * `:seq_number` - must carry an increment of the value carried in the previous
    outgoing message.
  * `:mpan_out_of_sync?` - when set by a sending node, indicates that the sender
    does not have MPAN state for the Multicast group used in the most recently
    received singlecast follow-up S2 Encap command sent by the destination of
    this command.
  * `:span_out_of_sync?` - when set by a sending node, indicates that the sender
    does not have a SPAn established for for the receiving node or was unable to
    decrypt the most recently received singlecast S2 Encap command sent by the
    destination of this command.
  * `:receivers_entropy_input` - when present, carries the Receiver's Entropy
    Input in preparation for new S2 transmissions based on the SPAN. Optional
    unless `span_out_of_sync` is set.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:seq_number, byte()}
          | {:mpan_out_of_sync?, boolean()}
          | {:span_out_of_sync?, boolean()}
          | {:receivers_entropy_input, <<_::128>>}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :s2_nonce_report,
      command_byte: 0x02,
      command_class: Security2,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    mpan_out_of_sync? = Command.param!(command, :mpan_out_of_sync?)
    span_out_of_sync? = Command.param!(command, :span_out_of_sync?)
    receivers_entropy_input = Command.param(command, :receivers_entropy_input, <<>>) || <<>>

    <<seq_number::8, 0::6, bool_to_bit(mpan_out_of_sync?)::1, bool_to_bit(span_out_of_sync?)::1,
      receivers_entropy_input::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<seq_number::8, _reserved::6, mpan_out_of_sync?::1, span_out_of_sync?::1,
          receivers_entropy_input::binary>>
      ) do
    {:ok,
     [
       seq_number: seq_number,
       mpan_out_of_sync?: bit_to_bool(mpan_out_of_sync?),
       span_out_of_sync?: bit_to_bool(span_out_of_sync?),
       receivers_entropy_input:
         if(receivers_entropy_input == <<>>, do: nil, else: receivers_entropy_input)
     ]}
  end
end
