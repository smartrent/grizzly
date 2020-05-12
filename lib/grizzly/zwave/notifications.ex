defmodule Grizzly.ZWave.Notifications do
  defmodule Generate do
    @moduledoc false
    @table [
      # {type_byte, type, event_byte, event}
      # Smoke Alarm (0x01)
      {0x01, :smoke_alarm, 0x00, :state_idle},
      {0x01, :smoke_alarm, 0x01, :smoke_detected_location_provided},
      {0x01, :smoke_alarm, 0x02, :smoked_detected},
      {0x01, :smoke_alarm, 0x03, :smoke_alarm_test},
      {0x01, :smoke_alarm, 0x04, :replacement_required},
      {0x01, :smoke_alarm, 0x05, :replacement_required_end_of_life},
      {0x01, :smoke_alarm, 0x06, :alarm_silenced},
      {0x01, :smoke_alarm, 0x07, :maintenance_required_planned_periodic_inspection},
      {0x01, :smoke_alarm, 0x08, :maintenance_required_dust_in_device},
      # Water (0x05)
      {0x05, :water, 0x00, :state_idle},
      {0x05, :water, 0x01, :water_leak_detected_known_location},
      {0x05, :water, 0x02, :water_leak_detected},
      {0x05, :water, 0x03, :water_level_dropped_known_location},
      {0x05, :water, 0x04, :water_level_dropped},
      {0x05, :water, 0x05, :replace_water_filter},
      {0x05, :water, 0x06, :water_flow_alarm},
      {0x05, :water, 0x07, :water_pressure_alarm},
      {0x05, :water, 0x08, :water_temperature_alarm},
      {0x05, :water, 0x09, :water_level_alarm},
      {0x05, :water, 0x0A, :sump_pump_active},
      {0x05, :water, 0x0B, :sump_pump_failure},
      {0x05, :water, 0xFE, :unknown},
      # Access Control (0x06)
      {0x06, :access_control, 0x00, :state_idle},
      {0x06, :access_control, 0x01, :manual_lock_operation},
      {0x06, :access_control, 0x02, :manual_unlock_operation},
      {0x06, :access_control, 0x03, :rf_lock_operation},
      {0x06, :access_control, 0x04, :rf_unlock_operation},
      # Home Security (0x07)
      {0x07, :home_security, 0x00, :state_idle},
      {0x07, :home_security, 0x01, :intrusion_location_provided},
      {0x07, :home_security, 0x02, :intrusion},
      {0x07, :home_security, 0x03, :tampering_product_cover_removed},
      {0x07, :home_security, 0x04, :tampering_invalid_code},
      {0x07, :home_security, 0x05, :glass_breakage_location_provided},
      {0x07, :home_security, 0x06, :glass_breakage},
      {0x07, :home_security, 0x07, :motion_detection},
      {0x07, :home_security, 0x08, :motion_detection_location_provided},
      {0x07, :home_security, 0x09, :tampering_product_moved},
      {0x07, :home_security, 0x0A, :impact_detected},
      {0x07, :home_security, 0x0B, :magnetic_field_interface_detected},
      {0x07, :home_security, 0xFE, :unknown_state},
      # Siren (0x0E)
      {0x0E, :siren, 0x00, :state_idle},
      {0x0E, :siren, 0x01, :state_active}
    ]

    defmacro __before_compile__(_) do
      type_to_byte =
        for {alarm_type_byte, alarm_type_name, _, _} <-
              Enum.uniq_by(@table, fn {_, type, _, _} -> type end) do
          quote do
            def type_to_byte(unquote(alarm_type_name)), do: unquote(alarm_type_byte)
          end
        end

      event_to_byte =
        for {_alarm_type_byte, alarm_type_name, alarm_event_byte, alarm_event_name} <- @table do
          quote do
            def event_to_byte(unquote(alarm_type_name), unquote(alarm_event_name)) do
              unquote(alarm_event_byte)
            end
          end
        end

      type_from_byte =
        for {alarm_type_byte, alarm_type_name, _, _} <-
              Enum.uniq_by(@table, fn {byte, _, _, _} -> byte end) do
          quote do
            def type_from_byte(unquote(alarm_type_byte)), do: {:ok, unquote(alarm_type_name)}
          end
        end

      event_from_byte =
        for {_, type, event_byte, event} <- @table do
          quote do
            def event_from_byte(unquote(type), unquote(event_byte)), do: {:ok, unquote(event)}
          end
        end

      quote do
        @type event :: atom()

        @type type :: atom()

        @doc """
        Get the byte for the event name
        """
        @spec type_to_byte(type()) :: byte()
        unquote(type_to_byte)

        @doc """
        Get the event byte given the event type
        """
        @spec event_to_byte(type(), event()) :: byte()
        unquote(event_to_byte)

        @doc """
        Get the type from the byte
        """
        @spec type_from_byte(byte()) :: {:ok, type()} | {:error, :invalid_type_byte}
        unquote(type_from_byte)
        def type_from_byte(_), do: {:error, :invalid_type_byte}

        @doc """
        Get the event from the byte given the notification type
        """
        @spec event_from_byte(type(), byte()) :: {:ok, event()} | {:error, :invalid_event_byte}
        unquote(event_from_byte)
        def event_from_byte(_, _), do: {:error, :invalid_event_byte}
      end
    end
  end

  @type zwave_alarm_status :: :deactivate | :activate

  @before_compile Generate
end
