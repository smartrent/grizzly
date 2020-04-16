defmodule Grizzly.ZWave.Commands.NodeProvisioningSet do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_SET` command

  This command adds a node to the node provisioning list.

  Params:

    - `:seq_number` - the network command sequence number (required)
    - `:dsk` - a DSK string for the device see `Grizzly.ZWave.DSK` for more
      more information (required)
    - `:meta_extensions` - a list of `Grizzly.ZWave.SmartStart.MetaExtension.t()`
      (optional default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.SmartStart.MetaExtension

  @type param ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:dsk, DSK.dsk_string()}
          | {:meta_extensions, [MetaExtension.t()]}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    params = Keyword.merge([meta_extensions: []], params)

    command = %Command{
      name: :node_provisioning_set,
      command_byte: 0x01,
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
    meta_extensions = Command.param!(command, :meta_extensions)
    {:ok, dsk_binary} = DSK.string_to_binary(Command.param!(command, :dsk))
    dsk_byte_size = byte_size(dsk_binary)

    <<seq_number, dsk_byte_size>> <> dsk_binary <> encode_meta_extensions(meta_extensions)
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<seq_number, _::size(3), dsk_byte_size::size(5),
          dsk_binary::size(dsk_byte_size)-unit(8)-binary, meta_extensions_binary::binary>>
      ) do
    with {:ok, dsk_string} <- DSK.binary_to_string(dsk_binary),
         {:ok, meta_extensions} <- MetaExtension.extensions_from_binary(meta_extensions_binary) do
      {:ok,
       [
         seq_number: seq_number,
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
           command: :node_provisioning_set
         }}
    end
  end

  defp encode_meta_extensions(meta_extensions),
    do:
      Enum.reduce(meta_extensions, <<>>, fn extension, extensions_bin ->
        extensions_bin <> MetaExtension.extension_to_binary(extension)
      end)
end
