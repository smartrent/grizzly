defmodule Grizzly.ZWave.Commands.NodeProvisioningReport do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_REPORT` command

  This command is used to advertise the contents of an entry in the node Provisioning List of the sending node

  Params:

    * `:seq_number` - the network command sequence number (required)
    * `:dsk` - a DSK string for the device see `Grizzly.ZWave.DSK` for more more information (optional)
    * `:meta_extensions` - a list of `Grizzly.ZWave.SmartStart.MetaExtension.t()` (optional default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.SmartStart.MetaExtension

  @type param() ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:dsk, DSK.t()}
          | {:meta_extensions, [MetaExtension.extension()]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :node_provisioning_report,
      command_byte: 0x06,
      command_class: NodeProvisioning,
      params: params_with_defaults(params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    dsk_binary = NodeProvisioning.optional_dsk_to_binary(Command.param!(command, :dsk))
    dsk_byte_size = byte_size(dsk_binary)
    meta_extensions = Command.param!(command, :meta_extensions)

    <<seq_number, 0x00::size(3), dsk_byte_size::size(5)>> <>
      dsk_binary <> NodeProvisioning.encode_meta_extensions(meta_extensions)
  end

  @impl true
  def decode_params(
        <<seq_number, _::size(3), dsk_byte_size::size(5),
          dsk_binary::size(dsk_byte_size)-unit(8)-binary, meta_extensions_binary::binary>>
      ) do
    dsk = NodeProvisioning.optional_binary_to_dsk(dsk_binary)
    meta_extensions = MetaExtension.parse(meta_extensions_binary)

    {:ok,
     [
       seq_number: seq_number,
       dsk: dsk,
       meta_extensions: meta_extensions
     ]}
  end

  defp params_with_defaults(params) do
    defaults = [meta_extensions: [], dsk: nil]
    Keyword.merge(defaults, params)
  end
end
