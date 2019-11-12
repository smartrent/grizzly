defmodule Grizzly.CommandClass.NodeProvisioning.Delete do
  @moduledoc """
  Command Options:

    * `:dsk` - A DSK string for provisioned devices, see `Grizzly.DSK`
               (can be nil - the default - to delete all provisioned nodes)
      for more details
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, DSK}
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          dsk: DSK.dsk_string(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:dsk, DSK.dsk_string()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct dsk: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{dsk: nil, seq_number: seq_number}) do
    binary =
      Packet.header(seq_number) <>
        <<0x78, 0x02, seq_number, 0x00>>

    {:ok, binary}
  end

  def encode(%__MODULE__{dsk: _dsk, seq_number: seq_number} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(
             command,
             %{
               dsk: {:encode_with, DSK, :string_to_binary}
             }
           ) do
      binary =
        Packet.header(seq_number) <>
          <<0x78, 0x02, seq_number, 0x00::size(3), byte_size(encoded.dsk)::size(5)>> <>
          encoded.dsk

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t} | {:done, {:error, :nack_response}} | {:done, :ok}
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

  def handle_response(command, _), do: {:continue, command}
end
