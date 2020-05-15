defmodule Grizzly.ZWave.Commands.NodeProvisioningListIterationReport do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_LIST_ITERATION_REPORT` command

  This command is used to advertise the contents of an entry in the Provisioning List of the sending node.

  Params:

    - `:seq_number` - the network command sequence number (required)
    - `:remaining_count` - indicates the remaining amount of entries in the Provisioning List
    - `:dsk` - a DSK string for the device see `Grizzly.ZWave.DSK` for more
      more information (optional)
    - `:meta_extensions` - a list of `Grizzly.ZWave.SmartStart.MetaExtension.t()`
      (optional default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.SmartStart.MetaExtension

  @type param ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:remaining_count, non_neg_integer()}
          | {:dsk, DSK.dsk_string()}
          | {:meta_extensions, [MetaExtension.t()]}

  @impl true
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

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    remaining_count = Command.param!(command, :remaining_count)
    meta_extensions = Command.param!(command, :meta_extensions)
    {:ok, dsk_binary} = DSK.string_to_binary(Command.param!(command, :dsk))
    dsk_byte_size = byte_size(dsk_binary)

    <<seq_number, remaining_count, 0x00::size(3), dsk_byte_size::size(5)>> <>
      dsk_binary <> NodeProvisioning.encode_meta_extensions(meta_extensions)
  end

  @impl true
  def decode_params(
        <<seq_number, remaining_count, _::size(3), dsk_byte_size::size(5),
          dsk_binary::size(dsk_byte_size)-unit(8)-binary, meta_extensions_binary::binary>>
      ) do
    with {:ok, dsk_string} <- DSK.binary_to_string(dsk_binary),
         {:ok, meta_extensions} <- MetaExtension.extensions_from_binary(meta_extensions_binary) do
      {:ok,
       [
         seq_number: seq_number,
         remaining_count: remaining_count,
         dsk: dsk_string,
         meta_extensions: meta_extensions
       ]}
    else
      {:error, reason} when reason in [:dsk_too_short, :dsk_too_long] ->
        {:error, %DecodeError{value: dsk_binary, param: :dsk, command: :node_provisioning_set}}

      {:error, _other} ->
        {:error,
         %DecodeError{
           value: meta_extensions_binary,
           param: :meta_extension,
           command: :node_provisioning_list_iteration_report
         }}
    end
  end

  defp params_with_defaults(params) do
    defaults = [meta_extensions: [], dsk: ""]
    Keyword.merge(defaults, params)
  end
end
