defmodule Grizzly.ZWave.Commands.NodeAddStatus do
  @moduledoc """
  Command for NODE_ADD_STATUS

  This command is normally the report from adding a node to the Z-Wave network

  Params:

    * `:seq_number` - the sequence number of the inclusion command
    * `:status` - the status of the inclusion
    * `:node_id` - the new id of the new Z-Wave node
    * `:listening?` - if the node is a listening node or not
    * `:basic_device_class` - the Z-Wave basic device class
    * `:generic_device_class` - the Z-Wave generic device class
    * `:specific_device_class` - the Z-Wave specific device class
    * `:command_classes` - a list of the command class the device supports, tagged by their security level
       used only if the device was included securely
    * `:granted_keys` - the security keys granted during S2 inclusion (optional)
    * `:kex_fail_type` - the error that occurred in the S2 bootstrapping (optional)

  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, Security}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type status :: :done | :failed | :security_failed

  @type tagged_command_classes ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}
  @type param ::
          {:node_id, Grizzly.node_id()}
          | {:status, status()}
          | {:seq_number, Grizzly.seq_number()}
          | {:listening?, boolean()}
          | {:basic_device_class, byte()}
          | {:generic_device_class, byte()}
          | {:specific_device_class, byte()}
          | {:command_classes, [tagged_command_classes]}
          | {:granted_keys, [Security.key()]}
          | {:kex_fail_type, Security.key_exchange_fail_type()}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params \\ []) do
    # TODO: validate params
    command = %Command{
      name: :node_add_status,
      command_byte: 0x02,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    status = Command.param!(command, :status)
    seq_number = Command.param!(command, :seq_number)

    if status == :failed do
      <<seq_number, encode_status(status), 0x00, node_id, 0x01>>
    else
      listening? = Command.param!(command, :listening?)
      basic_device_class = Command.param!(command, :basic_device_class)
      generic_device_class = Command.param!(command, :generic_device_class)
      specific_device_class = Command.param!(command, :specific_device_class)
      command_classes = Command.param!(command, :command_classes)

      # We add 6 to the length of the command classes to account for the 3 device
      # classes 2 Z-Wave protocol bytes and the node info length byte.
      # Also add the number of command classes plus 4 bytes for the separators
      # See SDS13784 4.4.8.2 for more details
      node_info_length = 6 + cc_count(command_classes) + 4

      # TODO: fix opt func bit (after the listening bit)
      binary =
        <<seq_number, encode_status(status), 0x00, node_id, node_info_length,
          encode_listening_bit(listening?)::size(1), 0x00::size(7), 0x00, basic_device_class,
          generic_device_class,
          specific_device_class>> <>
          CommandClasses.command_class_list_to_binary(command_classes)

      maybe_add_version_2_fields(command, binary)
    end
  end

  @impl true
  def decode_params(
        <<seq_number, status_byte, _reserved, node_id, node_info_length, listening?::size(1),
          _::size(7), _, basic_device_class, generic_device_class, specific_device_class,
          command_classes::binary>>
      ) do
    # TODO: decode the command classes correctly (currently assuming no extended command classes)
    # TODO: decode the device classes correctly

    tagged_command_classes_length = node_info_length - 6

    <<tagged_command_classes::size(tagged_command_classes_length)-binary, security_info::binary>> =
      command_classes

    {:ok,
     [
       status: decode_status(status_byte),
       seq_number: seq_number,
       node_id: node_id,
       listening?: listening? == 1,
       basic_device_class: basic_device_class,
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       command_classes: CommandClasses.command_class_list_from_binary(tagged_command_classes)
     ]
     |> maybe_decode_next_versions_fields(security_info)}
  end

  def decode_params(<<seq_number, status_byte, _reserved, node_id, 0x01>>) do
    {:ok,
     [
       status: decode_status(status_byte),
       seq_number: seq_number,
       node_id: node_id,
       listening?: false,
       basic_device_class: :unknown,
       generic_device_class: :unknown,
       specific_device_class: :unknown,
       command_classes: []
     ]}
  end

  @spec encode_status(status()) :: byte()
  def encode_status(:done), do: 0x06
  def encode_status(:failed), do: 0x07
  def encode_status(:security_failed), do: 0x09

  @spec decode_status(byte()) :: status()
  def decode_status(0x06), do: :done
  def decode_status(0x07), do: :failed
  def decode_status(0x09), do: :security_failed

  @spec encode_listening_bit(boolean()) :: byte()
  def encode_listening_bit(true), do: 0x01
  def encode_listening_bit(false), do: 0x00

  defp maybe_add_version_2_fields(command, command_bin) do
    case Command.param(command, :keys_granted) do
      nil ->
        command_bin

      keys_granted ->
        kex_failed_type = Command.param!(command, :kex_fail_type)

        command_bin <>
          <<Security.keys_to_byte(keys_granted), Security.failed_type_to_byte(kex_failed_type)>>
    end
  end

  defp maybe_decode_next_versions_fields(params, <<>>) do
    params
  end

  defp maybe_decode_next_versions_fields(params, <<keys_granted_byte, kex_failed_type_byte>>) do
    keys_granted = Security.byte_to_keys(keys_granted_byte)
    kex_failed_type = Security.failed_type_from_byte(kex_failed_type_byte)

    params ++ [keys_granted: keys_granted, kex_failed_type: kex_failed_type]
  end

  # in NODE_ADD_STATUS version 3 the input DSK length and input DSK are provided
  # if no input DSK was given then the input DSK length byte has to be 0.
  # if an input DSK was given then the length byte has be 16, followed by the 16 byte DSK
  defp maybe_decode_next_versions_fields(params, <<keys_granted_byte, kex_failed_type_byte, 0>>) do
    keys_granted = Security.byte_to_keys(keys_granted_byte)
    kex_failed_type = Security.failed_type_from_byte(kex_failed_type_byte)

    params ++ [keys_granted: keys_granted, kex_failed_type: kex_failed_type]
  end

  defp maybe_decode_next_versions_fields(
         params,
         <<keys_granted_byte, kex_failed_type_byte, 16, dsk::binary-size(16)>>
       ) do
    keys_granted = Security.byte_to_keys(keys_granted_byte)
    kex_failed_type = Security.failed_type_from_byte(kex_failed_type_byte)

    params ++ [keys_granted: keys_granted, kex_failed_type: kex_failed_type, input_dsk: dsk]
  end

  defp cc_count(tagged_command_classes) do
    tagged_command_classes |> Keyword.values() |> List.flatten() |> length()
  end
end
