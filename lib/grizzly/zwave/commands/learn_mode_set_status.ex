defmodule Grizzly.ZWave.Commands.LearnModeSetStatus do
  @moduledoc """
  This command is used to indicate the progress of the Learn Mode Set command.

  Params:

    * `:seq_number` - the command sequence number

    * `:status` - the outcome of the learn mode, one of :done, :failed or :security_failed

    * `:new_node_id` - the new node id assigned to the device

    * `:granted_keys` - indicates which network keys were granted during bootstrapping; a list with :s2_unauthenticated, :s2_authenticated,
                        :s2_access_control and/or :s0 (optional - v2)

    * `:kex_fail_type` - indicates which error occurred in case S2 bootstrapping was not successful; one of :none, :key, :scheme, :curves,
                        :decrypt, :cancel, :auth, :get, :verify or :report -- see Grizzly.ZWave.Security (optional - v2)

    * `:dsk` - the DSK of the including controller that performed S2 bootstrapping to the node (optional - v2)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError, DSK, Security}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @type status :: :done | :failed | :security_failed
  @type param ::
          {:seq_number, ZWave.seq_number()}
          | {:status, status}
          | {:new_node_id, Grizzly.Node.id()}
          | {:granted_keys, [Security.key()]}
          | {:kex_fail_type, Security.key_exchange_fail_type()}
          | {:dsk, DSK.t()}

  @impl true
  def new(params) do
    command = %Command{
      name: :learn_mode_set_status,
      command_byte: 0x02,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    status_byte = Command.param!(command, :status) |> encode_status()
    new_node_id = Command.param!(command, :new_node_id)
    granted_keys = Command.param(command, :granted_keys)

    if granted_keys == nil do
      <<seq_number, status_byte, 0x00, new_node_id>>
    else
      granted_keys_byte = Security.keys_to_byte(granted_keys)

      kex_fail_type_byte =
        Command.param!(command, :kex_fail_type) |> Security.failed_type_to_byte()

      dsk = Command.param!(command, :dsk)

      <<seq_number, status_byte, 0x00, new_node_id, granted_keys_byte, kex_fail_type_byte>> <>
        dsk.raw
    end
  end

  @impl true
  def decode_params(<<seq_number, status_byte, 0x00, new_node_id>>) do
    with {:ok, status} <- decode_status(status_byte) do
      {:ok, [seq_number: seq_number, status: status, new_node_id: new_node_id]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def decode_params(
        <<seq_number, status_byte, 0x00, new_node_id, granted_keys_byte, kex_fail_type_byte,
          dsk_binary::binary>>
      ) do
    granted_keys = Security.byte_to_keys(granted_keys_byte)
    kex_fail_type = Security.failed_type_from_byte(kex_fail_type_byte)

    with {:ok, status} <- decode_status(status_byte),
         dsk <- DSK.new(dsk_binary) do
      {:ok,
       [
         seq_number: seq_number,
         status: status,
         new_node_id: new_node_id,
         granted_keys: granted_keys,
         kex_fail_type: kex_fail_type,
         dsk: dsk
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_status(:done), do: 0x06
  defp encode_status(:failed), do: 0x07
  defp encode_status(:security_failed), do: 0x09

  defp decode_status(0x06), do: {:ok, :done}
  defp decode_status(0x07), do: {:ok, :failed}
  defp decode_status(0x09), do: {:ok, :security_failed}

  defp decode_status(byte),
    do: {:error, %DecodeError{value: byte, param: :status, command: :learn_mode_set_status}}
end
