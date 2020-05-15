defmodule Grizzly.ZWave.Commands.NodeProvisioningGet do
  @moduledoc """
  This module implements command COMMAND_NODE_PROVISIONING_GET of the COMMAND_CLASS_NODE_PROVISIONING command class

  This command is used to request the metadata information associated to an entry in the node
  Provisioning List

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:dsk` - the DSK for the entry being requested (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave

  @type param :: {:seq_number, ZWave.seq_number()} | {:dsk, DSK.dsk_string()}

  @impl true
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

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    {:ok, dsk_binary} = DSK.string_to_binary(Command.param!(command, :dsk))
    dsk_byte_size = byte_size(dsk_binary)

    <<seq_number, 0x00::size(3), dsk_byte_size::size(5)>> <> dsk_binary
  end

  @impl true
  def decode_params(
        <<seq_number, _::size(3), dsk_byte_size::size(5),
          dsk_binary::size(dsk_byte_size)-unit(8)-binary>>
      ) do
    with {:ok, dsk_string} <- DSK.binary_to_string(dsk_binary) do
      {:ok,
       [
         seq_number: seq_number,
         dsk: dsk_string
       ]}
    else
      {:error, reason} when reason in [:dsk_too_short, :dsk_too_long] ->
        {:error, %DecodeError{value: dsk_binary, param: :dsk, command: :node_provisioning_get}}
    end
  end
end
