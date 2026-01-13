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
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DSK

  @type param :: {:seq_number, ZWave.seq_number()} | {:dsk, DSK.t()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    dsk = Command.param!(command, :dsk)

    <<seq_number, byte_size(dsk.raw)>> <> dsk.raw
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, _, dsk_bin::binary>>) do
    {:ok, [seq_number: seq_number, dsk: DSK.new(dsk_bin)]}
  end
end
