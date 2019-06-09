defmodule Grizzly.CommandClass.Notification do
  alias Grizzly.CommandClass

  @type report :: %{
          command_class: CommandClass.name(),
          command: :report,
          vlaue: %{
            notification_type: atom() | {:unk, byte},
            notification_state: atom() | {:unk, byte}
          }
        }

  def type_from_byte(0x00), do: :reserved
  def type_from_byte(0x01), do: :smoke
  def type_from_byte(0x02), do: :co
  def type_from_byte(0x03), do: :co2
  def type_from_byte(0x04), do: :heat
  def type_from_byte(0x05), do: :water
  def type_from_byte(0x06), do: :access_control
  def type_from_byte(0x07), do: :burglar
  def type_from_byte(0x08), do: :power_management
  def type_from_byte(0x09), do: :system
  def type_from_byte(0x0A), do: :emergency
  def type_from_byte(0x0B), do: :clock
  def type_from_byte(0x0C), do: :first
  def type_from_byte(0x0D), do: :home_health
  def type_from_byte(0x0E), do: :siren
  def type_from_byte(0x0F), do: :water_valve
  def type_from_byte(0x10), do: :weather_alarm
  def type_from_byte(0x11), do: :irrigation
  def type_from_byte(0x12), do: :gas_alarm
  def type_from_byte(0x13), do: :pest_control
  def type_from_byte(0x14), do: :light_sensor
  def type_from_byte(0x15), do: :water_quality_monitoring
  def type_from_byte(0x16), do: :home_monitoring
  def type_from_byte(0xFF), do: :request_pending
  def type_from_byte(byte), do: {:unk, byte}

  @doc """
  Pass in the notification type and the byte for the event/state
  and get back the name of the event/state
  """
  def state_from_byte(:smoke, 0x00), do: :idle
  def state_from_byte(:smoke, 0x01), do: :smoke_detected_known_location
  def state_from_byte(:smoke, 0x03), do: :smoke_detected
  def state_from_byte(:smoke, 0x04), do: :replacement_required
  def state_from_byte(:smoke, 0x05), do: :replacement_required_end_of_life
  def state_from_byte(:smoke, 0x07), do: :maintenance_required_periodic
  def state_from_byte(:smoke, 0x08), do: :maintenance_required_dust
  def state_from_byte(:smoke, 0xFE), do: :unknown

  def state_from_byte(:power_management, 0x02), do: :ac_mains_disconnected
  def state_from_byte(:power_management, 0x03), do: :ac_mains_reconnected

  def state_from_byte(:water, 0x00), do: :idle
  def state_from_byte(:water, 0x01), do: :water_leak_detected_known_location
  def state_from_byte(:water, 0x02), do: :water_leak_detected
  def state_from_byte(:water, 0x03), do: :water_level_dropped_known_location
  def state_from_byte(:water, 0x04), do: :water_level_dropped
  def state_from_byte(:water, 0x05), do: :replace_water_filter
  def state_from_byte(:water, 0x06), do: :water_flow_alarm
  def state_from_byte(:water, 0x07), do: :water_pressure_alarm
  def state_from_byte(:water, 0x08), do: :water_temperature_alarm
  def state_from_byte(:water, 0x09), do: :water_level_alarm
  def state_from_byte(:water, 0x0A), do: :sump_pump_active
  def state_from_byte(:water, 0x0B), do: :sump_pump_failure
  def state_from_byte(:water, 0xFE), do: :unknown

  def state_from_byte(:access_control, 0x00), do: :idle
  def state_from_byte(:access_control, 0x01), do: :manual_lock_operation
  def state_from_byte(:access_control, 0x02), do: :manual_unlock_operation
  def state_from_byte(:access_control, 0x03), do: :rf_lock_operation
  def state_from_byte(:access_control, 0x04), do: :rf_unlock_operation
  def state_from_byte(:access_control, 0x05), do: :keypad_lock_operation
  def state_from_byte(:access_control, 0x06), do: :keypad_unlock_operation
  def state_from_byte(:access_control, 0x07), do: :manual_not_fully_locked_operation
  def state_from_byte(:access_control, 0x08), do: :rf_not_fully_locked_operation
  def state_from_byte(:access_control, 0x09), do: :auto_lock_locked_operation
  def state_from_byte(:access_control, 0x0A), do: :auto_lock_not_fully_locked_operation
  def state_from_byte(:access_control, 0x0B), do: :lock_jammed
  def state_from_byte(:access_control, 0x0C), do: :all_user_codes_deleted
  def state_from_byte(:access_control, 0x0D), do: :single_user_code_deleted
  def state_from_byte(:access_control, 0x0E), do: :new_user_code_added
  def state_from_byte(:access_control, 0x0F), do: :new_user_code_not_added_duplicate
  def state_from_byte(:access_control, 0x10), do: :keypad_temporarily_disabled
  def state_from_byte(:access_control, 0x11), do: :keypad_busy
  def state_from_byte(:access_control, 0x12), do: :new_program_code_entered
  def state_from_byte(:access_control, 0x13), do: :manually_enter_user_code_exceeds_code_limit
  def state_from_byte(:access_control, 0x14), do: :unlock_by_rf_with_invalid_user_code
  def state_from_byte(:access_control, 0x15), do: :locked_by_rf_with_invalid_user_code
  def state_from_byte(:access_control, 0x16), do: :window_or_door_is_open
  def state_from_byte(:access_control, 0x17), do: :window_or_door_is_closed
  def state_from_byte(:access_control, 0x18), do: :window_or_door_handle_is_open
  def state_from_byte(:access_control, 0x19), do: :window_or_door_handle_is_closed
  def state_from_byte(:access_control, 0x20), do: :messaging_user_code_entered_via_keypad
  def state_from_byte(:access_control, 0x40), do: :barrier_performing_initialization_process
  def state_from_byte(:access_control, 0x41), do: :barrier_operation_exceeded_time_limit
  def state_from_byte(:access_control, 0x42), do: :barrier_operation_force_exceeded
  def state_from_byte(:access_control, 0x43), do: :barrier_operation_exceeded_mechanical_limit

  def state_from_byte(:access_control, 0x44),
    do: :barrier_unable_to_perform_operation_ul_requirements

  def state_from_byte(:access_control, 0x45),
    do: :barrier_unattended_operation_disabled_ul_requirements

  def state_from_byte(:access_control, 0x46), do: :barrier_failed_operation_malfunction
  def state_from_byte(:access_control, 0x47), do: :barrier_vacation_mode
  def state_from_byte(:access_control, 0x48), do: :barrier_safety_beam_obstacle
  def state_from_byte(:access_control, 0x49), do: :barrier_sensor_not_detected
  def state_from_byte(:access_control, 0x4A), do: :barrier_sensor_low_battery
  def state_from_byte(:access_control, 0x4B), do: :barrier_short_in_wall_station_wires

  def state_from_byte(:access_control, 0x4C),
    do: :barrier_associated_with_non_zwave_remote_control

  def state_from_byte(:access_control, 0xFE), do: :unknown

  def state_from_byte(:burglar, 0x00), do: :idle
  def state_from_byte(:burglar, 0x01), do: :intrusion_located
  def state_from_byte(:burglar, 0x02), do: :intrusion
  def state_from_byte(:burglar, 0x03), do: :tampering
  def state_from_byte(:burglar, 0x04), do: :tampering_invalid_code
  def state_from_byte(:burglar, 0x05), do: :glass_breakage_located
  def state_from_byte(:burglar, 0x06), do: :glass_breakage
  def state_from_byte(:burglar, 0x07), do: :motion_detection_located
  def state_from_byte(:burglar, 0x08), do: :motion_detection
  def state_from_byte(:burglar, 0x09), do: :tampering_moved
  def state_from_byte(:burglar, 0x0A), do: :impact_detected
  def state_from_byte(:burglar, 0xFE), do: :unknown

  def state_from_byte(:siren, 0x00), do: :idle
  def state_from_byte(:siren, 0x01), do: :active

  def state_from_byte(:gas_alarm, 0x00), do: :idle
  def state_from_byte(:gas_alarm, 0x01), do: :combustible_gas_located
  def state_from_byte(:gas_alarm, 0x02), do: :combustible_gas
  def state_from_byte(:gas_alarm, 0x03), do: :toxic_gas_located
  def state_from_byte(:gas_alarm, 0x04), do: :toxic_gas
  def state_from_byte(:gas_alarm, 0x05), do: :gas_alarm_test
  def state_from_byte(:gas_alarm, 0x06), do: :replacement_required
  def state_from_byte(:gas_alarm, 0xFE), do: :unknown

  def state_from_byte(_notification_type, byte), do: {:unk, byte}
end
