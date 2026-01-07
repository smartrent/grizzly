defmodule Grizzly.ZWave.CommandClasses do
  @moduledoc """
  Utilities for encoding and decoding command classes and command class lists.
  """

  import Grizzly.ZWave.GeneratedMappings, only: [command_class_mappings: 0]

  alias CommandClasses.NetworkManagementInstallationMaintenance, as: NMIM
  alias Grizzly.ZWave.CommandClasses

  require Logger

  @type command_class_list :: [
          non_secure_supported: list(atom()),
          non_secure_controlled: list(atom()),
          secure_supported: list(atom()),
          secure_controlled: list(atom())
        ]

  @type command_class :: atom()

  def cc_module!(command_class) do
    case command_class do
      :alarm -> CommandClasses.Alarm
      :antitheft -> CommandClasses.Antitheft
      :antitheft_unlock -> CommandClasses.AntitheftUnlock
      :application_status -> CommandClasses.ApplicationStatus
      :association -> CommandClasses.Association
      :association_group_info -> CommandClasses.AssociationGroupInfo
      :barrier_operator -> CommandClasses.BarrierOperator
      :basic -> CommandClasses.Basic
      :battery -> CommandClasses.Battery
      :crc_16_encap -> CommandClasses.CRC16Encap
      :central_scene -> CommandClasses.CentralScene
      :clock -> CommandClasses.Clock
      :configuration -> CommandClasses.Configuration
      :device_reset_locally -> CommandClasses.DeviceResetLocally
      :door_lock -> CommandClasses.DoorLock
      :firmware_update_md -> CommandClasses.FirmwareUpdateMD
      :hail -> CommandClasses.Hail
      :humidity_control_mode -> CommandClasses.HumidityControlMode
      :humidity_control_operating_state -> CommandClasses.HumidityControlOperatingState
      :humidity_control_setpoint -> CommandClasses.HumidityControlSetpoint
      :indicator -> CommandClasses.Indicator
      :manufacturer_specific -> CommandClasses.ManufacturerSpecific
      :meter -> CommandClasses.Meter
      :multi_channel -> CommandClasses.MultiChannel
      :multi_channel_association -> CommandClasses.MultiChannelAssociation
      :multi_cmd -> CommandClasses.MultiCommand
      :network_management_basic_node -> CommandClasses.NetworkManagementBasicNode
      :network_management_inclusion -> CommandClasses.NetworkManagementInclusion
      :network_management_installation_maintenance -> NMIM
      :network_management_proxy -> CommandClasses.NetworkManagementProxy
      :no_operation -> CommandClasses.NoOperation
      :node_naming -> CommandClasses.NodeNaming
      :node_provisioning -> CommandClasses.NodeProvisioning
      :powerlevel -> CommandClasses.Powerlevel
      :s0 -> CommandClasses.S0
      :scene_activation -> CommandClasses.SceneActivation
      :scene_actuator_conf -> CommandClasses.SceneActuatorConf
      :schedule_entry_lock -> CommandClasses.ScheduleEntryLock
      :security_2 -> CommandClasses.Security2
      :sensor_binary -> CommandClasses.SensorBinary
      :sensor_multilevel -> CommandClasses.SensorMultilevel
      :sound_switch -> CommandClasses.SoundSwitch
      :supervision -> CommandClasses.Supervision
      :switch_binary -> CommandClasses.SwitchBinary
      :switch_multilevel -> CommandClasses.SwitchMultilevel
      :thermostat_fan_mode -> CommandClasses.ThermostatFanMode
      :thermostat_fan_state -> CommandClasses.ThermostatFanState
      :thermostat_mode -> CommandClasses.ThermostatMode
      :thermostat_operating_state -> CommandClasses.ThermostatOperatingState
      :thermostat_setback -> CommandClasses.ThermostatSetback
      :thermostat_setpoint -> CommandClasses.ThermostatSetpoint
      :time -> CommandClasses.Time
      :time_parameters -> CommandClasses.TimeParameters
      :user_code -> CommandClasses.UserCode
      :user_credential -> CommandClasses.UserCredential
      :version -> CommandClasses.Version
      :wake_up -> CommandClasses.WakeUp
      :window_covering -> CommandClasses.WindowCovering
      :zip -> CommandClasses.ZIP
      :zip_gateway -> CommandClasses.ZIPGateway
      :zwaveplus_info -> CommandClasses.ZwaveplusInfo
      _ -> raise ArgumentError, "Unknown command class: #{inspect(command_class)}"
    end
  end

  @doc """
  Get the byte representation of the command class
  """
  @spec to_byte(command_class()) :: byte()
  def to_byte(command_class) do
    Map.fetch!(command_class_mappings(), command_class)
  end

  @spec from_byte(byte()) :: {:ok, command_class()} | {:error, :unsupported_command_class}
  def from_byte(byte) do
    Enum.find_value(command_class_mappings(), {:error, :unsupported_command_class}, fn {cc, b} ->
      if b == byte, do: {:ok, cc}
    end)
  end

  @spec valid?(command_class()) :: boolean()
  def valid?(command_class) do
    Map.has_key?(command_class_mappings(), command_class)
  end

  @doc """
  Merges command class lists in a way that's more resilient to some Z/IP Gateway
  bugs. The list provided in the second argument is merged into the first.

  In particular, there's a Z/IP Gateway bug where it can lose track of a node's
  supported command classes. If this happens while the node is failing, a Node
  Info Cached Report can come back with an empty command class list. If requesting
  the NIF works but the controller doesn't receive an S0/S2 Commands Supported Report
  (e.g. due to interference), the secure command class lists will be empty.
  """
  @spec merge(command_class_list(), command_class_list()) :: command_class_list()
  def merge(list1, list2) do
    Keyword.merge(list1, list2, fn _key, val1, val2 ->
      if val2 == [] do
        val1
      else
        val2
      end
    end)
  end

  @doc """
  Turn the list of command classes into the binary representation outlined in
  the Network-Protocol command class specification.

  TODO: add more details
  """
  @spec command_class_list_to_binary([command_class_list()]) :: binary()
  def command_class_list_to_binary(command_class_list) do
    non_secure_supported = Keyword.get(command_class_list, :non_secure_supported, [])
    non_secure_controlled = Keyword.get(command_class_list, :non_secure_controlled, [])
    secure_supported = Keyword.get(command_class_list, :secure_supported, [])
    secure_controlled = Keyword.get(command_class_list, :secure_controlled, [])
    non_secure_supported_bin = for cc <- non_secure_supported, into: <<>>, do: <<to_byte(cc)>>
    non_secure_controlled_bin = for cc <- non_secure_controlled, into: <<>>, do: <<to_byte(cc)>>
    secure_supported_bin = for cc <- secure_supported, into: <<>>, do: <<to_byte(cc)>>
    secure_controlled_bin = for cc <- secure_controlled, into: <<>>, do: <<to_byte(cc)>>

    bin =
      non_secure_supported_bin
      |> maybe_concat_command_classes(:non_secure_controlled, non_secure_controlled_bin)
      |> maybe_concat_command_classes(:secure_supported, secure_supported_bin)
      |> maybe_concat_command_classes(:secure_controlled, secure_controlled_bin)

    if bin == <<>> do
      <<0>>
    else
      bin
    end
  end

  @doc """
  Turn the binary representation that is outlined in the Network-Protocol specs
  """
  @spec command_class_list_from_binary(binary()) :: [command_class_list()]
  def command_class_list_from_binary(binary) do
    binary
    |> :erlang.binary_to_list()
    |> group_extended_command_classes()
    |> parse_and_categorize_command_classes()
  end

  defp group_extended_command_classes(command_class_id_list) do
    command_class_id_list
    |> Enum.reduce({nil, []}, fn
      # Extended command classes start with 0xF1..0xFF
      byte, {nil, acc} when byte in 0xF1..0xFF ->
        {byte, acc}

      # Second byte of an extended command class
      byte, {prev_byte, acc} when prev_byte in 0xF1..0xFF ->
        {nil, [prev_byte * 2 ** 8 + byte | acc]}

      # All other command classes
      byte, {nil, acc} ->
        {nil, [byte | acc]}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp parse_and_categorize_command_classes(command_class_id_list) do
    command_class_id_list
    |> Enum.reduce(
      {:non_secure_supported,
       [
         non_secure_supported: [],
         non_secure_controlled: [],
         secure_supported: [],
         secure_controlled: []
       ]},
      fn
        0xEF, {:non_secure_supported, command_classes} ->
          {:non_secure_controlled, command_classes}

        0xF100, {_, command_classes} ->
          {:secure_supported, command_classes}

        0xEF, {:secure_supported, command_classes} ->
          {:secure_controlled, command_classes}

        # Skip extended command classes
        command_class_id, acc when command_class_id > 0xFF ->
          acc

        command_class_id, {security, command_classes} ->
          case from_byte(command_class_id) do
            {:ok, command_class} ->
              {security, Keyword.update(command_classes, security, [], &(&1 ++ [command_class]))}

            {:error, :unsupported_command_class} ->
              # Skip unsupported command classes
              {security, command_classes}
          end
      end
    )
    |> elem(1)
  end

  defp maybe_concat_command_classes(binary, _, <<>>), do: binary

  defp maybe_concat_command_classes(binary, :non_secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>

  defp maybe_concat_command_classes(binary, :secure_supported, ccs_bin),
    do: binary <> <<0xF1, 0x00, ccs_bin::binary>>

  defp maybe_concat_command_classes(binary, :secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>
end
