defmodule Grizzly.ZWave.Commands.NodeProvisioningSet do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_SET` command

  This command adds a node to the node provisioning list.

  Params:

    * `:seq_number` - the network command sequence number (required)
    * `:dsk` - a DSK string for the device see `Grizzly.ZWave.DSK` for more
      more information (required)
    * `:meta_extensions` - a list of `Grizzly.ZWave.SmartStart.MetaExtension.t()`
      (optional default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.SmartStart.MetaExtension

  @type param() ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:dsk, DSK.t()}
          | {:meta_extensions, [MetaExtension.extension()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    dsk = dsk_bin_from_command!(command)

    meta_extensions =
      command
      |> Command.param!(:meta_extensions)
      |> NodeProvisioning.encode_meta_extensions()

    <<seq_number, 0x00::3, byte_size(dsk)::5, dsk::binary, meta_extensions::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # TODO: same problem with no function call
  def decode_params(
        <<seq_number, _::3, dsk_byte_size::5, dsk_binary::binary-size(dsk_byte_size)-unit(8),
          meta_extensions_binary::binary>>
      ) do
    with {:ok, dsk_string} <- DSK.binary_to_string(dsk_binary),
         meta_extensions <- MetaExtension.parse(meta_extensions_binary) do
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

  defp dsk_bin_from_command!(cmd) do
    case Command.param!(cmd, :dsk) do
      %DSK{raw: raw} ->
        raw

      dsk when is_binary(dsk) and byte_size(dsk) == 16 ->
        dsk

      dsk when is_binary(dsk) ->
        case DSK.parse(dsk) do
          {:ok, dsk} -> dsk.raw
          {:error, :invalid_dsk} -> raise ArgumentError, "invalid DSK: #{inspect(dsk)}"
        end
    end
  end
end
