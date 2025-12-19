defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusion do
  @moduledoc """
  Network Management Inclusion Command Class

  This command class provides the commands for adding and removing Z-Wave nodes
  to the Z-Wave network
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.DeviceClasses
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.Security

  require Logger

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
  * `:granted_keys` - S2 keys granted by the user during the time of inclusion
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
          optional(:granted_keys) => [Security.key()],
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
  * `:granted_keys` - S2 keys granted by the user during the time of inclusion
  * `:kex_fail_type` - the type of key exchange failure if there is one
  """
  @type extended_node_info_report() :: %{
          required(:listening?) => boolean(),
          required(:basic_device_class) => DeviceClasses.basic_device_class(),
          required(:generic_device_class) => DeviceClasses.generic_device_class(),
          required(:specific_device_class) => DeviceClasses.specific_device_class(),
          required(:command_classes) => [tagged_command_classes()],
          required(:granted_keys) => [Security.key()],
          required(:kex_fail_type) => Security.key_exchange_fail_type()
        }

  @doc """
  Parse node information from node add status and extended node add status reports
  """
  @spec parse_node_info(binary()) :: node_info_report() | extended_node_info_report()
  def parse_node_info(
        <<node_info_length, listening?::1, _::7, _opt_func, basic_device_class,
          generic_device_class, specific_device_class,
          command_classes::binary-size(node_info_length - 6), rest::binary>>
      ) do
    # TODO: decode the command classes correctly (currently assuming no extended command classes)

    basic_device_class = DeviceClasses.decode_basic(basic_device_class)

    generic_device_class =
      DeviceClasses.decode_generic(generic_device_class)

    specific_device_class =
      DeviceClasses.decode_specific(
        generic_device_class,
        specific_device_class
      )

    # node info length includes: node_info_length, listening?, opt_func, basic class,
    # generic class, specific class, and the command class list. Granted keys, kex fail
    # type, and DSK are not included.

    %{
      listening?: listening? == 1,
      basic_device_class: basic_device_class,
      generic_device_class: generic_device_class,
      specific_device_class: specific_device_class,
      command_classes: CommandClasses.command_class_list_from_binary(command_classes)
    }
    |> parse_optional_fields(rest)
  end

  # This accounts for an off-by-one error observed (rarely) in node add status
  # frames sent by Z/IP Gateway when a SmartStart node fails security bootstrapping.
  # node_info_length is supposed to include itself, but in that case, it sometimes
  # doesn't.
  def parse_node_info(<<node_info_length, rest::binary-size(node_info_length - 2)>>),
    do: parse_node_info(<<node_info_length - 1, rest::binary>>)

  # node_info_length can be 1 (note that it's self-inclusive) when an inclusion error
  # occurs and no node info is available
  def parse_node_info(<<1>>), do: %{}

  defp parse_optional_fields(info, <<>>), do: info

  defp parse_optional_fields(info, <<granted_keys, kex_fail_type>>),
    do: put_security_info(info, granted_keys, kex_fail_type)

  defp parse_optional_fields(info, <<granted_keys, kex_fail_type, 0x00>>),
    do: put_security_info(info, granted_keys, kex_fail_type)

  defp parse_optional_fields(info, <<granted_keys, kex_fail_type, 16, dsk::binary-size(16)>>),
    do: info |> put_security_info(granted_keys, kex_fail_type) |> put_dsk(dsk)

  defp parse_optional_fields(info, extra) do
    Logger.warning(
      "[Grizzly] Unable to parse fields after command class list in (Ext.) Node Add Status: #{inspect(extra, base: :hex)}"
    )

    info
  end

  defp put_security_info(info, granted_keys, kex_fail_type) do
    info
    |> Map.put(:granted_keys, Security.byte_to_keys(granted_keys))
    |> Map.put(:kex_fail_type, Security.failed_type_from_byte(kex_fail_type))
  end

  defp put_dsk(info, dsk_bin) do
    info
    |> Map.put(:input_dsk, DSK.new(dsk_bin))
  end
end
