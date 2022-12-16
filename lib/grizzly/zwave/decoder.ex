defmodule Grizzly.ZWave.Decoder do
  @moduledoc false

  defmodule Generate do
    @moduledoc false
    alias Grizzly.ZWave.{Command, Commands, DecodeError, ZWaveError}

    @mappings [
      # {command_class_byte, command_byte, command_module}
      # Basic
      {0x20, 0x01, Commands.BasicSet},
      {0x20, 0x02, Commands.BasicGet},
      {0x20, 0x03, Commands.BasicReport},
      # Application status
      {0x22, 0x01, Commands.ApplicationBusy},
      {0x22, 0x02, Commands.ApplicationRejectedRequest},
      # Battery
      {0x80, 0x02, Commands.BatteryGet},
      {0x80, 0x03, Commands.BatteryReport},
      # Z/IP (0x23)
      {0x23, 0x02, Commands.ZIPPacket},
      {0x23, 0x03, Commands.ZIPKeepAlive},
      # Switch Binary (0x25)
      {0x25, 0x01, Commands.SwitchBinarySet},
      {0x25, 0x02, Commands.SwitchBinaryGet},
      {0x25, 0x03, Commands.SwitchBinaryReport},
      # Switch Multilevel (0x26)
      {0x26, 0x01, Commands.SwitchMultilevelSet},
      {0x26, 0x02, Commands.SwitchMultilevelGet},
      {0x26, 0x03, Commands.SwitchMultilevelReport},
      {0x26, 0x04, Commands.SwitchMultilevelStartLevelChange},
      {0x26, 0x05, Commands.SwitchMultiLevelStopLevelChange},
      # Sensor binary
      {0x30, 0x02, Commands.SensorBinaryGet},
      {0x30, 0x03, Commands.SensorBinaryReport},
      # Network Management Inclusion (0x34)
      {0x34, 0x01, Commands.NodeAdd},
      {0x34, 0x02, Commands.NodeAddStatus},
      {0x34, 0x03, Commands.NodeRemove},
      {0x34, 0x04, Commands.NodeRemoveStatus},
      {0x34, 0x07, Commands.FailedNodeRemove},
      {0x34, 0x08, Commands.FailedNodeRemoveStatus},
      {0x34, 0x11, Commands.NodeAddKeysReport},
      {0x34, 0x12, Commands.NodeAddKeysSet},
      {0x34, 0x13, Commands.NodeAddDSKReport},
      {0x34, 0x14, Commands.NodeAddDSKSet},
      {0x34, 0x15, Commands.SmartStartJoinStarted},
      {0x34, 0x16, Commands.ExtendedNodeAddStatus},
      # Network Management Basic Node (0x4D)
      {0x4D, 0x01, Commands.LearnModeSet},
      {0x4D, 0x02, Commands.LearnModeSetStatus},
      {0x4D, 0x03, Commands.NetworkUpdateRequest},
      {0x4D, 0x04, Commands.NetworkUpdateRequestStatus},
      {0x4D, 0x07, Commands.DefaultSetComplete},
      {0x4D, 0x08, Commands.DSKGet},
      {0x4D, 0x09, Commands.DSKReport},
      # Schedule Entry Lock
      {0x4E, 0x01, Commands.ScheduleEntryLockEnableSet},
      {0x4E, 0x02, Commands.ScheduleEntryLockEnableAllSet},
      {0x4E, 0x03, Commands.ScheduleEntryLockWeekDaySet},
      {0x4E, 0x04, Commands.ScheduleEntryLockWeekDayGet},
      {0x4E, 0x05, Commands.ScheduleEntryLockWeekDayReport},
      {0x4E, 0x06, Commands.ScheduleEntryLockYearDaySet},
      {0x4E, 0x07, Commands.ScheduleEntryLockYearDayGet},
      {0x4E, 0x08, Commands.ScheduleEntryLockYearDayReport},
      {0x4E, 0x09, Commands.ScheduleEntryTypeSupportedGet},
      {0x4E, 0x0A, Commands.ScheduleEntryTypeSupportedReport},
      {0x4E, 0x0B, Commands.ScheduleEntryLockTimeOffsetGet},
      {0x4E, 0x0C, Commands.ScheduleEntryLockTimeOffsetReport},
      {0x4E, 0x0D, Commands.ScheduleEntryLockTimeOffsetSet},
      {0x4E, 0x0E, Commands.ScheduleEntryLockDailyRepeatingGet},
      {0x4E, 0x0F, Commands.ScheduleEntryLockDailyRepeatingReport},
      {0x4E, 0x10, Commands.ScheduleEntryLockDailyRepeatingSet},
      # Network Management Proxy (0x52)
      {0x52, 0x01, Commands.NodeListGet},
      {0x52, 0x02, Commands.NodeListReport},
      {0x52, 0x03, Commands.NodeInfoCachedGet},
      {0x52, 0x04, Commands.NodeInfoCacheReport},
      {0x52, 0x06, Commands.NetworkManagementMultiChannelEndPointReport},
      {0x52, 0x07, Commands.NetworkManagementMultiChannelCapabilityGet},
      {0x52, 0x08, Commands.NetworkManagementMultiChannelCapabilityReport},
      {0x52, 0x0B, Commands.FailedNodeListGet},
      {0x52, 0x0C, Commands.FailedNodeListReport},
      # Multi Channel
      {0x60, 0x07, Commands.MultiChannelEndpointGet},
      {0x60, 0x08, Commands.MultiChannelEndpointReport},
      {0x60, 0x09, Commands.MultiChannelCapabilityGet},
      {0x60, 0x0A, Commands.MultiChannelCapabilityReport},
      {0x60, 0x0B, Commands.MultiChannelEndpointFind},
      {0x60, 0x0C, Commands.MultiChannelEndpointFindReport},
      {0x60, 0x0D, Commands.MultiChannelCommandEncapsulation},
      {0x60, 0x0E, Commands.MultiChannelAggregatedMembersGet},
      {0x60, 0x0F, Commands.MultiChannelAggregatedMembersReport},
      # Association group info
      {0x59, 0x01, Commands.AssociationGroupNameGet},
      {0x59, 0x02, Commands.AssociationGroupNameReport},
      {0x59, 0x03, Commands.AssociationGroupInfoGet},
      {0x59, 0x04, Commands.AssociationGroupInfoReport},
      {0x59, 0x05, Commands.AssociationGroupCommandListGet},
      {0x59, 0x06, Commands.AssociationGroupCommandListReport},
      # Central scene
      {0x5B, 0x01, Commands.CentralSceneSupportedGet},
      {0x5B, 0x02, Commands.CentralSceneSupportedReport},
      {0x5B, 0x03, Commands.CentralSceneNotification},
      {0x5B, 0x04, Commands.CentralSceneConfigurationSet},
      {0x5B, 0x05, Commands.CentralSceneConfigurationGet},
      {0x5B, 0x06, Commands.CentralSceneConfigurationReport},
      # Antitheft
      {0x5D, 0x01, Commands.AntitheftSet},
      {0x5D, 0x02, Commands.AntitheftGet},
      {0x5D, 0x03, Commands.AntitheftReport},
      # Zwabeplus Info
      {0x5E, 0x01, Commands.ZwaveplusInfoGet},
      {0x5E, 0x02, Commands.ZwaveplusInfoReport},
      # Z/IP Gateway
      {0x5F, 0x0C, Commands.ApplicationNodeInfoGet},
      {0x5F, 0x0D, Commands.ApplicationNodeInfoReport},
      # Door Lock
      {0x62, 0x01, Commands.DoorLockOperationSet},
      {0x62, 0x02, Commands.DoorLockOperationGet},
      {0x62, 0x03, Commands.DoorLockOperationReport},
      {0x62, 0x04, Commands.DoorLockConfigurationSet},
      {0x62, 0x05, Commands.DoorLockConfigurationGet},
      {0x62, 0x06, Commands.DoorLockConfigurationReport},
      {0x62, 0x07, Commands.DoorLockCapabilitiesGet},
      {0x62, 0x08, Commands.DoorLockCapabilitiesReport},

      # User Code
      {0x63, 0x01, Commands.UserCodeSet},
      {0x63, 0x02, Commands.UserCodeGet},
      {0x63, 0x03, Commands.UserCodeReport},
      {0x63, 0x04, Commands.UserCodeUsersNumberGet},
      {0x63, 0x05, Commands.UserCodeUsersNumberReport},
      # Barrier Operator
      {0x66, 0x01, Commands.BarrierOperatorSet},
      {0x66, 0x02, Commands.BarrierOperatorGet},
      {0x66, 0x03, Commands.BarrierOperatorReport},
      {0x66, 0x04, Commands.BarrierOperatorSignalSupportedGet},
      {0x66, 0x05, Commands.BarrierOperatorSignalSupportedReport},
      {0x66, 0x06, Commands.BarrierOperatorSignalSet},
      {0x66, 0x07, Commands.BarrierOperatorSignalGet},
      {0x66, 0x08, Commands.BarrierOperatorSignalReport},

      # Network management installation maintenance
      {0x67, 0x02, Commands.PriorityRouteGet},
      {0x67, 0x03, Commands.PriorityRouteReport},
      {0x67, 0x04, Commands.StatisticsGet},
      {0x67, 0x05, Commands.StatisticsReport},
      {0x67, 0x06, Commands.StatisticsClear},
      {0x67, 0x07, Commands.RssiGet},
      {0x67, 0x08, Commands.RssiReport},
      {0x67, 0x09, Commands.S2ResynchronizationEvent},
      {0x67, 0x0E, Commands.ZWaveLongRangeChannelReport},

      # Window Covering
      {0x6A, 0x01, Commands.WindowCoveringSupportedGet},
      {0x6A, 0x02, Commands.WindowCoveringSupportedReport},
      {0x6A, 0x03, Commands.WindowCoveringGet},
      {0x6A, 0x04, Commands.WindowCoveringReport},
      {0x6A, 0x05, Commands.WindowCoveringSet},
      {0x6A, 0x06, Commands.WindowCoveringStartLevelChange},
      {0x6A, 0x07, Commands.WindowCoveringStopLevelChange},

      # Supervision
      {0x6C, 0x01, Commands.SupervisionGet},
      {0x6C, 0x02, Commands.SupervisionReport},
      # Configuration
      {0x70, 0x04, Commands.ConfigurationSet},
      {0x70, 0x05, Commands.ConfigurationGet},
      {0x70, 0x06, Commands.ConfigurationReport},
      {0x70, 0x07, Commands.ConfigurationBulkSet},
      {0x70, 0x08, Commands.ConfigurationBulkGet},
      {0x70, 0x09, Commands.ConfigurationBulkReport},
      {0x70, 0x0A, Commands.ConfigurationNameGet},
      {0x70, 0x0B, Commands.ConfigurationNameReport},
      {0x70, 0x0E, Commands.ConfigurationPropertiesGet},
      {0x70, 0x0F, Commands.ConfigurationPropertiesReport},
      # Alarm
      {0x71, 0x01, Commands.AlarmEventSupportedGet},
      {0x71, 0x02, Commands.AlarmEventSupportedReport},
      {0x71, 0x04, Commands.AlarmGet},
      {0x71, 0x05, Commands.AlarmReport},
      {0x71, 0x06, Commands.AlarmSet},
      {0x71, 0x07, Commands.AlarmTypeSupportedGet},
      {0x71, 0x08, Commands.AlarmTypeSupportedReport},
      # Manufacturer Specific
      {0x72, 0x04, Commands.ManufacturerSpecificGet},
      {0x72, 0x05, Commands.ManufacturerSpecificReport},
      {0x72, 0x06, Commands.ManufacturerSpecificDeviceSpecificGet},
      {0x72, 0x07, Commands.ManufacturerSpecificDeviceSpecificReport},
      # Antitheft unlock
      {0x7E, 0x01, Commands.AntitheftUnlockGet},
      {0x7E, 0x02, Commands.AntitheftUnlockReport},
      {0x7E, 0x03, Commands.AntitheftUnlockSet},
      # Hail
      {0x82, 0x01, Commands.Hail},
      # Association (0x85)
      {0x85, 0x01, Commands.AssociationSet},
      {0x85, 0x02, Commands.AssociationGet},
      {0x85, 0x03, Commands.AssociationReport},
      {0x85, 0x04, Commands.AssociationRemove},
      {0x85, 0x05, Commands.AssociationGroupingsGet},
      {0x85, 0x06, Commands.AssociationGroupingsReport},
      {0x85, 0x0B, Commands.AssociationSpecificGroupGet},
      {0x85, 0x0C, Commands.AssociationSpecificGroupReport},
      # Multi Channel Association (0x8E)
      {0x8E, 0x01, Commands.MultiChannelAssociationSet},
      {0x8E, 0x02, Commands.MultiChannelAssociationGet},
      {0x8E, 0x03, Commands.MultiChannelAssociationReport},
      {0x8E, 0x04, Commands.MultiChannelAssociationRemove},
      {0x8E, 0x05, Commands.MultiChannelAssociationGroupingsGet},
      {0x8E, 0x06, Commands.MultiChannelAssociationGroupingsReport},
      # Version (0x86)
      {0x86, 0x11, Commands.VersionGet},
      {0x86, 0x12, Commands.VersionReport},
      {0x86, 0x13, Commands.VersionCommandClassGet},
      {0x86, 0x14, Commands.VersionCommandClassReport},
      # Firmware Update Metadata
      {0x7A, 0x01, Commands.FirmwareMDGet},
      {0x7A, 0x02, Commands.FirmwareMDReport},
      {0x7A, 0x03, Commands.FirmwareUpdateMDRequestGet},
      {0x7A, 0x04, Commands.FirmwareUpdateMDRequestReport},
      {0x7A, 0x05, Commands.FirmwareUpdateMDGet},
      {0x7A, 0x06, Commands.FirmwareUpdateMDReport},
      {0x7A, 0x07, Commands.FirmwareUpdateMDStatusReport},
      {0x7A, 0x08, Commands.FirmwareUpdateActivationSet},
      {0x7A, 0x09, Commands.FirmwareUpdateActivationReport},
      # Wake Up
      {0x84, 0x04, Commands.WakeUpIntervalSet},
      {0x84, 0x05, Commands.WakeUpIntervalSet},
      {0x84, 0x06, Commands.WakeUpIntervalReport},
      {0x84, 0x07, Commands.WakeUpNotification},
      {0x84, 0x08, Commands.WakeUpNoMoreInformation},
      {0x84, 0x09, Commands.WakeUpIntervalCapabilitiesGet},
      {0x84, 0x0A, Commands.WakeUpIntervalCapabilitiesReport},
      # Sensor multilevel
      {0x31, 0x01, Commands.SensorMultilevelSupportedSensorGet},
      {0x31, 0x02, Commands.SensorMultilevelSupportedSensorReport},
      {0x31, 0x04, Commands.SensorMultilevelGet},
      {0x31, 0x05, Commands.SensorMultilevelReport},
      # Meter
      {0x32, 0x01, Commands.MeterGet},
      {0x32, 0x02, Commands.MeterReport},
      # Thermostat mode
      {0x40, 0x01, Commands.ThermostatModeSet},
      {0x40, 0x02, Commands.ThermostatModeGet},
      {0x40, 0x03, Commands.ThermostatModeReport},
      {0x40, 0x04, Commands.ThermostatModeSupportedGet},
      {0x40, 0x05, Commands.ThermostatModeSupportedReport},
      # Thermostat setpoint
      {0x43, 0x01, Commands.ThermostatSetpointSet},
      {0x43, 0x02, Commands.ThermostatSetpointGet},
      {0x43, 0x03, Commands.ThermostatSetpointReport},
      {0x43, 0x04, Commands.ThermostatSetpointSupportedGet},
      {0x43, 0x05, Commands.ThermostatSetpointSupportedReport},
      # Thermostat fan mode
      {0x44, 0x01, Commands.ThermostatFanModeSet},
      {0x44, 0x02, Commands.ThermostatFanModeGet},
      {0x44, 0x03, Commands.ThermostatFanModeReport},
      # Thermostat fan state
      {0x45, 0x02, Commands.ThermostatFanStateGet},
      {0x45, 0x03, Commands.ThermostatFanStateReport},
      # Thermostat setback
      {0x47, 0x01, Commands.ThermostatSetbackSet},
      {0x47, 0x02, Commands.ThermostatSetbackGet},
      {0x47, 0x03, Commands.ThermostatSetbackReport},
      # CRC 16 encapsulation
      {0x56, 0x01, Commands.CRC16Encap},
      # Thermostat operating state
      {0x42, 0x02, Commands.ThermostatOperatingStateGet},
      {0x42, 0x03, Commands.ThermostatOperatingStateReport},
      # Powerlevel
      {0x73, 0x01, Commands.PowerlevelSet},
      {0x73, 0x02, Commands.PowerlevelGet},
      {0x73, 0x03, Commands.PowerlevelReport},
      {0x73, 0x04, Commands.PowerlevelTestNodeSet},
      {0x73, 0x05, Commands.PowerlevelTestNodeGet},
      {0x73, 0x06, Commands.PowerlevelTestNodeReport},
      # Node provisioning
      {0x78, 0x01, Commands.NodeProvisioningSet},
      {0x78, 0x02, Commands.NodeProvisioningDelete},
      {0x78, 0x03, Commands.NodeProvisioningListIterationGet},
      {0x78, 0x04, Commands.NodeProvisioningListIterationReport},
      {0x78, 0x05, Commands.NodeProvisioningGet},
      {0x78, 0x06, Commands.NodeProvisioningReport},
      # Node naming and location
      {0x77, 0x01, Commands.NodeNameSet},
      {0x77, 0x02, Commands.NodeNameGet},
      {0x77, 0x03, Commands.NodeNameReport},
      {0x77, 0x04, Commands.NodeLocationSet},
      {0x77, 0x05, Commands.NodeLocationGet},
      {0x77, 0x06, Commands.NodeLocationReport},
      # Clock
      {0x81, 0x04, Commands.ClockSet},
      {0x81, 0x05, Commands.ClockGet},
      {0x81, 0x06, Commands.ClockReport},
      # Time parameters
      {0x8B, 0x01, Commands.TimeParametersSet},
      {0x8B, 0x02, Commands.TimeParametersGet},
      {0x8B, 0x03, Commands.TimeParametersReport},
      # Device reset locally
      {0x5A, 0x01, Commands.DeviceResetLocallyNotification},
      # Time
      {0x8A, 0x01, Commands.TimeGet},
      {0x8A, 0x02, Commands.TimeReport},
      {0x8A, 0x03, Commands.DateGet},
      {0x8A, 0x04, Commands.DateReport},
      {0x8A, 0x05, Commands.TimeOffsetSet},
      {0x8A, 0x06, Commands.TimeOffsetGet},
      {0x8A, 0x07, Commands.TimeOffsetReport},
      # Indicator
      {0x87, 0x01, Commands.IndicatorSet},
      {0x87, 0x02, Commands.IndicatorGet},
      {0x87, 0x03, Commands.IndicatorReport},
      {0x87, 0x04, Commands.IndicatorSupportedGet},
      {0x87, 0x05, Commands.IndicatorSupportedReport},
      {0x87, 0x06, Commands.IndicatorDescriptionGet},
      {0x87, 0x07, Commands.IndicatorDescriptionReport},
      # Scene activation
      {0x2B, 0x01, Commands.SceneActovationSet},
      # Scene actuator configuration
      {0x2C, 0x01, Commands.SceneActuatorConfSet},
      {0x2C, 0x02, Commands.SceneActuatorConfGet},
      {0x2C, 0x03, Commands.SceneActuatorConfReport}
    ]

    defmacro __before_compile__(_) do
      # Exceptions
      from_binary =
        for {command_class_byte, command_byte, command_module} <- @mappings do
          quote do
            def from_binary(
                  <<unquote(command_class_byte), unquote(command_byte), params::binary>>
                ),
                do: decode(unquote(command_module), params)
          end
        end

      command_module =
        for {command_class_byte, command_byte, command_module} <- @mappings do
          quote do
            def command_module(unquote(command_class_byte), unquote(command_byte)),
              do: {:ok, unquote(command_module)}
          end
        end

      quote do
        @spec from_binary(binary) :: {:ok, Command.t()} | {:error, DecodeError.t()}
        unquote(from_binary)

        # No Operation (0x00) - There is no command byte or args for this command, only the command class byte
        def from_binary(<<0x00>>), do: decode(Commands.NoOperation, [])

        def from_binary(other), do: {:error, %ZWaveError{binary: other}}

        @spec command_module(byte, byte) :: {:ok, module} | {:error, :unsupported_command}
        unquote(command_module)
        def command_module(_cc_byte, _c_byte), do: {:error, :unsupported_command}

        defp decode(command_impl, params) do
          case command_impl.decode_params(params) do
            {:ok, decoded_params} ->
              command_impl.new(decoded_params)

            {:error, %DecodeError{}} = error ->
              error

            %DecodeError{} = error ->
              {:error, error}
          end
        end
      end
    end
  end

  @before_compile Generate
end
