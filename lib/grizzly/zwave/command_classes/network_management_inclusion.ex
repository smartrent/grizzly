defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusion do
  @moduledoc """
  Network Management Inclusion Command Class

  This command class provides the commands for adding and removing Z-Wave nodes
  to the Z-Wave network
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.{CommandClasses, DecodeError, DeviceClasses, DSK, Security}

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

  @type tx_opt :: :null | :low_power | :explore

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

  @spec tx_opt_to_byte(tx_opt()) :: byte()
  def tx_opt_to_byte(:null), do: 0x00
  def tx_opt_to_byte(:low_power), do: 0x02
  def tx_opt_to_byte(:explore), do: 0x20

  @spec tx_opt_from_byte(byte()) :: {:ok, tx_opt()} | {:error, DecodeError.t()}
  def tx_opt_from_byte(0x00), do: {:ok, :null}
  def tx_opt_from_byte(0x02), do: {:ok, :low_power}
  def tx_opt_from_byte(0x20), do: {:ok, :explore}

  def tx_opt_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :tx_opt}}

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
          required(:basic_device_class) => DeviceClasses.basic_device_class(),
          required(:generic_device_class) => DeviceClasses.generic_device_class(),
          required(:specific_device_class) => DeviceClasses.specific_device_class(),
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
          required(:basic_device_class) => DeviceClasses.basic_device_class(),
          required(:generic_device_class) => DeviceClasses.generic_device_class(),
          required(:specific_device_class) => DeviceClasses.specific_device_class(),
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

    {:ok, basic_device_class} = DeviceClasses.basic_device_class_from_byte(basic_device_class)

    {:ok, generic_device_class} =
      DeviceClasses.generic_device_class_from_byte(generic_device_class)

    {:ok, specific_device_class} =
      DeviceClasses.specific_device_class_from_byte(
        generic_device_class,
        specific_device_class
      )

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

  # node_info_length can be 1 (note that it's self-inclusive) when an inclusion error
  # occurs as no node info is available
  def parse_node_info(<<1>>), do: %{}

  defp parse_additional_node_info(node_info, additional_info, command_class_length)
       when command_class_length <= 0 or byte_size(additional_info) == 0,
       do: node_info |> Map.put(:command_classes, [])

  defp parse_additional_node_info(node_info, additional_info, command_class_length) do
    {command_classes_bin, more_info} =
      case additional_info do
        <<command_classes_bin::binary-size(command_class_length), more_info::binary>> ->
          {command_classes_bin, more_info}

        # This case is to handle a Z/IP Gateway bug where the node_info_length field is
        # off by one. This appears to happen when S2 bootstrapping fails for a node being
        # included via SmartStart, but there may be other cases as well.
        <<command_classes_bin::binary-size(command_class_length - 1)>> ->
          {command_classes_bin, <<>>}
      end

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
end
