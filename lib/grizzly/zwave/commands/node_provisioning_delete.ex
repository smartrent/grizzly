defmodule Grizzly.ZWave.Commands.NodeProvisioningDelete do
  @moduledoc """
  Node Provisioning Delete Command

  This command is useful for deleting Z-Wave nodes from the node provisioning
  list.

  After deleting a Z-Wave node entry from the node provisioning list you will
  still have run excluded the node from the Z-Wave network.

  Params:

    * `:seq_number` - the sequence number for the network command (required)
    * `:dsk` - the DSK string of the node to delete, please see
      `Grizzly.ZWave.DSK` for more information (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning

  @type param :: {:seq_number, ZWave.seq_number()} | {:dsk, DSK.t()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :node_provisioning_delete,
      command_byte: 0x02,
      command_class: NodeProvisioning,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    dsk = Command.param!(command, :dsk)

    <<seq_number, byte_size(dsk.raw)>> <> dsk.raw
  end

  @impl true
  @spec decode_params(binary) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, _, dsk_bin::binary>>) do
    {:ok, [seq_number: seq_number, dsk: DSK.new(dsk_bin)]}
  end
end
