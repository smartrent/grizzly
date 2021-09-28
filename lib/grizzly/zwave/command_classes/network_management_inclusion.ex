defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusion do
  @moduledoc """
  Network Management Inclusion Command Class

  This command class provides the commands for adding and removing Z-Wave nodes
  to the Z-Wave network
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.{DSK, CommandClasses, Security}

  @typedoc """
  The status of the inclusion process

  * `:done` - the inclusion process is done without error
  * `:failed` - the inclusion process is done with failure, the device is not
    included
  * `:security_failed` - the inclusion process is done, the device is included
    but their was an error during the security negotiations. Device \
    functionality will be degraded.
  """
  @type node_add_status() :: :done | :failed | :security_failed

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x34

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :network_management_inclusion

  @doc """
  Parse the node add status byte into an atom
  """
  @spec parse_node_add_status(0x06 | 0x07 | 0x09) :: node_add_status()
  def parse_node_add_status(0x06), do: :done
  def parse_node_add_status(0x07), do: :failed
  def parse_node_add_status(0x09), do: :security_failed

  @doc """
  Encode a `node_add_status()` to a byte
  """
  @spec node_add_status_to_byte(node_add_status()) :: 0x06 | 0x07 | 0x09
  def node_add_status_to_byte(:done), do: 0x06
  def node_add_status_to_byte(:failed), do: 0x07
  def node_add_status_to_byte(:security_failed), do: 0x09

  @typedoc """
  Command classes have different ways they are support for each device
  """
  @type tagged_command_classes() ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}

  @typedoc """
  Node info report

  node information from a node add status report

  * `:listening?` - is the device a listening device
  * `:basic_device_class` - the basic device class
  * `:generic_device_class` - the generic device class
  * `:specific_device_class` - the specific device class
  * `:command_classes` - list of command classes the new device supports
  * `:keys_granted` - S2 keys granted by the user during the time of inclusion
    version 2 and above
  * `:kex_fail_type` - the type of key exchange failure if there is one version
    2 and above
  * `input_dsk` - the DSK of the device version 3 and above. If the info report is used
  """
  @type node_info_report() :: %{
          required(:seq_number) => byte(),
          required(:node_id) => Grizzly.ZWave.node_id(),
          required(:status) => node_add_status(),
          required(:listening?) => boolean(),
          required(:basic_device_class) => byte(),
          required(:generic_device_class) => byte(),
          required(:specific_device_class) => byte(),
          required(:command_classes) => [tagged_command_classes()],
          optional(:keys_granted) => [Security.key()],
          optional(:kex_fail_type) => Security.key_exchange_fail_type(),
          optional(:input_dsk) => Security.key_exchange_fail_type()
        }

  @typedoc """
  Extended node info report

  Node information from an extended node add status report

  * `:listening?` - is the device a listening device
  * `:basic_device_class` - the basic device class
  * `:generic_device_class` - the generic device class
  * `:specific_device_class` - the specific device class
  * `:command_classes` - list of command classes the new device supports
  * `:keys_granted` - S2 keys granted by the user during the time of inclusion
  * `:kex_fail_type` - the type of key exchange failure if there is one
  """
  @type extended_node_info_report() :: %{
          required(:listening?) => boolean(),
          required(:basic_device_class) => byte(),
          required(:generic_device_class) => byte(),
          required(:specific_device_class) => byte(),
          required(:command_classes) => [tagged_command_classes()],
          required(:keys_granted) => [Security.key()],
          required(:kex_fail_type) => Security.key_exchange_fail_type()
        }

  @doc """
  Parse node information from node add status and extended node add status reports
  """
  @spec parse_node_info(binary()) :: node_info_report() | extended_node_info_report()
  def parse_node_info(
        <<node_info_length, listening?::1, _::7, _opt_func, basic_device_class,
          generic_device_class, specific_device_class, more_info::binary>>
      ) do
    # TODO: decode the command classes correctly (currently assuming no extended command classes)
    # TODO: decode the device classes correctly

    # node info length includes: node_info_length, listening?, opt_func, and 3 devices classes
    # to get the length of command classes we have to subject 6 bytes.
    command_class_length = node_info_length - 6

    Map.new()
    |> Map.put(:listening?, listening? == 1)
    |> Map.put(:basic_device_class, basic_device_class)
    |> Map.put(:generic_device_class, generic_device_class)
    |> Map.put(:specific_device_class, specific_device_class)
    |> parse_additional_node_info(more_info, command_class_length)
  end

  defp parse_additional_node_info(node_info, additional_info, command_class_length) do
    <<command_classes_bin::binary-size(command_class_length), more_info::binary>> =
      additional_info

    command_classes = CommandClasses.command_class_list_from_binary(command_classes_bin)

    node_info
    |> Map.put(:command_classes, command_classes)
    |> parse_optional_fields(more_info)
  end

  defp parse_optional_fields(info, <<>>), do: info

  defp parse_optional_fields(info, <<keys_granted, kex_fail_type>>) do
    info
    |> put_security_info(keys_granted, kex_fail_type)
  end

  defp parse_optional_fields(info, <<keys_granted, kex_fail_type, 0x00>>) do
    info
    |> put_security_info(keys_granted, kex_fail_type)
  end

  defp parse_optional_fields(info, <<keys_granted, kex_fail_type, 16, dsk::binary-size(16)>>) do
    info
    |> put_security_info(keys_granted, kex_fail_type)
    |> put_dsk(dsk)
  end

  defp put_security_info(info, keys_granted, kex_fail_type) do
    info
    |> Map.put(:keys_granted, Security.byte_to_keys(keys_granted))
    |> Map.put(:kex_fail_type, Security.failed_type_from_byte(kex_fail_type))
  end

  defp put_dsk(info, dsk_bin) do
    info
    |> Map.put(:input_dsk, DSK.new(dsk_bin))
  end

  # When encoding for 16 bit node ids in the context of the node remove family of
  # command (node ids > 255) the 8 bit node id byte of the binary needs to be set
  # to 0xFF as per the specification.

  # In ZWA_Z-Wave Network Protocol Command Class Specification 12.0.0.pdf:

  # Sections 4.5.13.2 and 4.4.13.3:
  #   "This field MUST be set to 0xFF if the removed NodeID is greater than 255."

  # This only is used for version 4 parsing and encoding.
  @remove_node_id_is_16_bit 0xFF

  @doc """
  Encodes node ids for version 4 of the `NetworkManagementInclusion` command
  class
  """
  @spec encode_node_remove_node_id_v4(Grizzly.ZWave.node_id()) :: binary()
  def encode_node_remove_node_id_v4(node_id) when node_id < 233 do
    <<node_id, 0x00::16>>
  end

  def encode_node_remove_node_id_v4(node_id) when node_id > 255 and node_id <= 65535 do
    <<@remove_node_id_is_16_bit, node_id::16>>
  end

  @doc """
  Parse the node id parameters part of the node remove commands.
  """
  @spec parse_node_remove_node_id(binary()) :: Grizzly.ZWave.node_id()
  def parse_node_remove_node_id(<<node_id>>), do: node_id
  def parse_node_remove_node_id(<<@remove_node_id_is_16_bit, node_id::16>>), do: node_id
  def parse_node_remove_node_id(<<node_id, _ignored::16>>), do: node_id
end
