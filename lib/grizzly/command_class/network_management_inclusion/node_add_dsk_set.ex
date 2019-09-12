defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAddDSKSet do
  @moduledoc """
  Command module for working with NETWORK_MANAGEMENT_INCLUSION NODE_ADD_DSK_SET command.

  command options:

    * `:accept`: - Boolean that indicates if S2 requested keys should be granted
    * `:input_dsk` - The 5 digit pin code found on the device
    * `:input_dsk_length` - the lengh of the DSK
    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number of times to resend the command (default 2)
  """
  @behaviour Grizzly.Command

  @typedoc """
  The `input_dsk` field is the 5 digit pin found on the
  joining node, normally near the QR code.
  """
  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          accept: boolean(),
          input_dsk_length: non_neg_integer(),
          retries: non_neg_integer(),
          input_dsk: non_neg_integer()
        }

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.NetworkManagementInclusion

  defstruct seq_number: nil, accept: true, input_dsk_length: nil, input_dsk: "", retries: 2

  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number, input_dsk_length: 0} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             accept: {:encode_with, NetworkManagementInclusion, :encode_accept}
           }) do
      {:ok,
       Packet.header(seq_number) <>
         <<0x34, 0x14, seq_number, encoded.accept::size(1), 0::size(7), 0>>}
    end
  end

  def encode(
        %__MODULE__{
          seq_number: seq_number,
          input_dsk_length: input_dsk_length,
          input_dsk: input_dsk
        } = command
      ) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             accept: {:encode_with, NetworkManagementInclusion, :encode_accept},
             input_dsk_length: {:bits, 4}
           }) do
      dsk = <<input_dsk::size(input_dsk_length)-unit(8)>>

      {:ok,
       Packet.header(seq_number) <>
         <<0x34, 0x14, seq_number, encoded.accept::size(1), input_dsk_length::size(7),
           dsk::binary>>}
    end
  end

  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: 0}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: n} = command, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(command, _packet) do
    {:continue, command}
  end
end
