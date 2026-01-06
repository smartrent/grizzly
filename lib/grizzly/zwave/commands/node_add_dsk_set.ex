defmodule Grizzly.ZWave.Commands.NodeAddDSKSet do
  @moduledoc """
  Command to set the DSK for a including node

  Params:

    * `:seq_number` - the sequence number for the command (required)
    * `:accept` - the including controller accepts the inclusion process
       and should proceed with adding the including node (required)
    * `input_dsk_length` - the length of the DSK provided (required)
    * `input_dsk` - the DSK pin for the including node (required)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.DSK

  @type param ::
          {:seq_number, ZWave.seq_number()}
          | {:accept, boolean()}
          | {:input_dsk_length, 0..0xF}
          | {:input_dsk, DSK.t()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add_dsk_set,
      command_byte: 0x14,
      command_class: NetworkManagementInclusion,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    accept = Command.param!(command, :accept)
    input_dsk_length = Command.param!(command, :input_dsk_length)
    input_dsk = Command.param(command, :input_dsk)

    dsk = dsk_to_binary(input_dsk, input_dsk_length)

    <<seq_number, bool_to_bit(accept)::size(1), 0::3, input_dsk_length::4>> <> dsk
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(
        <<seq_number, accept::1, _::3, input_dsk_length::4,
          input_dsk::binary-size(input_dsk_length)-unit(8)>>
      ) do
    {:ok,
     [
       seq_number: seq_number,
       accept: bit_to_bool(accept),
       input_dsk_length: input_dsk_length,
       input_dsk: DSK.new(input_dsk)
     ]}
  end

  defp dsk_to_binary(nil, dsk_len) when dsk_len == 0 do
    <<>>
  end

  defp dsk_to_binary(0, dsk_len) when dsk_len == 0 do
    <<>>
  end

  defp dsk_to_binary(%DSK{} = dsk, dsk_len) do
    :binary.part(dsk.raw, 0, dsk_len)
  end
end
