defmodule Grizzly.ZWave.Commands.NodeProvisioningListIterationReport do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_LIST_ITERATION_REPORT` command

  This command is used to advertise the contents of an entry in the Provisioning
  List of the sending node.

  Params:

    - `:seq_number` - the network command sequence number (required)
    - `:remaining_count` - indicates the remaining amount of entries in the
      Provisioning List
    - `:dsk` - a `Grizzly.ZWave.DSK.t()` for the device (optional)
    - `:meta_extensions` - a list of `Grizzly.ZWave.SmartStart.MetaExtension.t()`
      (optional default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.SmartStart.MetaExtension

  @type param() ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:remaining_count, non_neg_integer()}
          | {:dsk, DSK.t()}
          | {:meta_extensions, [MetaExtension.extension()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :node_provisioning_list_iteration_report,
      command_byte: 0x04,
      command_class: NodeProvisioning,
      params: params_with_defaults(params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    remaining_count = Command.param!(command, :remaining_count)
    meta_extensions = Command.param!(command, :meta_extensions)
    dsk_binary = NodeProvisioning.optional_dsk_to_binary(Command.param!(command, :dsk))
    dsk_byte_size = byte_size(dsk_binary)

    <<seq_number, remaining_count, 0x00::3, dsk_byte_size::5>> <>
      dsk_binary <> NodeProvisioning.encode_meta_extensions(meta_extensions)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<seq_number, remaining_count, _::3, dsk_byte_size::5,
          dsk_binary::binary-size(dsk_byte_size)-unit(8), meta_extensions_binary::binary>>
      ) do
    dsk = NodeProvisioning.optional_binary_to_dsk(dsk_binary)
    meta_extensions = MetaExtension.parse(meta_extensions_binary)

    {:ok,
     [
       seq_number: seq_number,
       remaining_count: remaining_count,
       dsk: dsk,
       meta_extensions: meta_extensions
     ]}
  end

  defp params_with_defaults(params) do
    defaults = [meta_extensions: [], dsk: ""]
    Keyword.merge(defaults, params)
  end
end
