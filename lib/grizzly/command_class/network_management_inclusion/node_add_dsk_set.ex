defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAddDSKSet do
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

  defstruct seq_number: nil, accept: true, input_dsk_length: nil, input_dsk: "", retries: 2

  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  def encode(%__MODULE__{seq_number: seq_number, accept: accept, input_dsk_length: 0}) do
    {:ok,
     Packet.header(seq_number) <>
       <<0x34, 0x14, seq_number, encode_accept(accept)::size(1), 0::size(7), 0>>}
  end

  def encode(%__MODULE__{
        seq_number: seq_number,
        accept: accept,
        input_dsk_length: dsk_length,
        input_dsk: dsk
      }) do
    dsk = <<dsk::size(dsk_length)-unit(8)>>

    {:ok,
     Packet.header(seq_number) <>
       <<0x34, 0x14, seq_number, encode_accept(accept)::size(1), dsk_length::size(7),
         dsk::binary>>}
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

  defp encode_accept(true), do: 1
  defp encode_accept(false), do: 0
end
