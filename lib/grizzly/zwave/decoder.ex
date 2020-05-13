defmodule Grizzly.ZWave.Decoder do
  @moduledoc false

  defmodule Generate do
    @moduledoc false
    alias Grizzly.ZWave.{Command, Commands, DecodeError}

    @mappings [
      # {command_class_byte, command_byte, command_module}
      # Basic
      {0x20, 0x01, Commands.BasicSet},
      {0x20, 0x02, Commands.BasicGet},
      {0x20, 0x03, Commands.BasicReport},
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
      {0x26, 0x01, Commands.SwitchMultiLevelSet},
      {0x26, 0x02, Commands.SwitchMultiLevelGet},
      {0x26, 0x03, Commands.SwitchMultilevelReport},
      {0x26, 0x04, Commands.SwitchMultilevelStartLevelChange},
      {0x26, 0x05, Commands.SwitchMultiLevelStopLevelChange},
      # Network Management Inclusion (0x34)
      {0x34, 0x01, Commands.NodeAdd},
      {0x34, 0x02, Commands.NodeAddStatus},
      {0x34, 0x03, Commands.NodeRemove},
      {0x34, 0x04, Commands.NodeRemoveStatus},
      {0x34, 0x11, Commands.NodeAddKeysReport},
      {0x34, 0x12, Commands.NodeAddKeysSet},
      {0x34, 0x13, Commands.NodeAddDSKReport},
      {0x34, 0x14, Commands.NodeAddDSKSet},
      # Network Management Basic Node (0x4D)
      {0x4D, 0x07, Commands.DefaultSetComplete},
      {0x4D, 0x08, Commands.DSKGet},
      {0x4D, 0x09, Commands.DSKReport},
      # Network Management Proxy (0x52)
      {0x52, 0x01, Commands.NodeListGet},
      {0x52, 0x02, Commands.NodeListReport},
      {0x52, 0x04, Commands.NodeInfoCacheReport},
      # Door Lock
      {0x62, 0x01, Commands.DoorLockOperationSet},
      {0x62, 0x02, Commands.DoorLockOperationGet},
      {0x62, 0x03, Commands.DoorLockOperationReport},
      # User Code
      {0x63, 0x01, Commands.UserCodeSet},
      # Configuration
      {0x70, 0x04, Commands.ConfigurationSet},
      # Alarm
      {0x71, 0x05, Commands.AlarmReport},
      # Manufacturer Specific
      {0x72, 0x04, Commands.ManufacturerSpecificGet},
      {0x72, 0x05, Commands.ManufacturerSpecificReport},
      {0x72, 0x06, Commands.ManufacturerSpecificDeviceSpecificGet},
      {0x72, 0x07, Commands.ManufacturerSpecificDeviceSpecificReport},
      # Association (0x85)
      {0x85, 0x03, Commands.AssociationReport},
      # Version (0x86)
      {0x86, 0x11, Commands.VersionGet},
      {0x86, 0x12, Commands.VersionReport},
      {0x86, 0x13, Commands.CommandClassGet},
      {0x86, 0x14, Commands.CommandClassReport},
      # Firmware Update Metadata
      {0x7A, 0x01, Commands.FirmwareUpdateMDGet},
      {0x7A, 0x02, Commands.FirmwareMDReport},
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
      # Thermostat mode
      {0x40, 0x01, Commands.ThermostatModeSet},
      {0x40, 0x02, Commands.ThermostatModeGet},
      {0x40, 0x03, Commands.ThermostatModeReport},
      # Thermostat setpoint
      {0x43, 0x01, Commands.ThermostatSetpointSet},
      {0x43, 0x02, Commands.ThermostatSetpointGet},
      {0x43, 0x03, Commands.ThermostatSetpointReport}
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

      quote do
        @spec from_binary(binary) :: {:ok, Command.t()} | {:error, DecodeError.t()}
        unquote(from_binary)

        # No Operation (0x00) - There is no command byte or args for this command, only the command class byte
        def from_binary(<<0x00>>), do: decode(Commands.NoOperation, [])

        defp decode(command_impl, params) do
          case command_impl.decode_params(params) do
            {:ok, decoded_params} ->
              command_impl.new(decoded_params)

            {:error, %DecodeError{}} = error ->
              error
          end
        end
      end
    end
  end

  @before_compile Generate
end
