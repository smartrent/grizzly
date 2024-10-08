defmodule Grizzly.ZWave.Commands.NodeProvisioningGet do
  @moduledoc """
  This module implements command COMMAND_NODE_PROVISIONING_GET of the
  COMMAND_CLASS_NODE_PROVISIONING command class

  This command is used to request the metadata information associated to an
  entry in the node Provisioning List

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:dsk` - the `Grizzly.ZWave.DSK.t()` for the entry being requested
      (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning

  @type param :: {:seq_number, ZWave.seq_number()} | {:dsk, DSK.t()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :node_provisioning_get,
      command_byte: 0x05,
      command_class: NodeProvisioning,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    dsk = Command.param!(command, :dsk)
    dsk_byte_size = byte_size(dsk.raw)

    <<seq_number, 0x00::3, dsk_byte_size::5>> <> dsk.raw
  end

  @impl Grizzly.ZWave.Command
  # TODO: circle back to this
  def decode_params(
        <<seq_number, _::3, dsk_byte_size::5, dsk_binary::binary-size(dsk_byte_size)-unit(8)>>
      ) do
    dsk = DSK.new(dsk_binary)

    {:ok,
     [
       seq_number: seq_number,
       dsk: dsk
     ]}
  end
end
