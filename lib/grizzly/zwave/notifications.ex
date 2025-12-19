defmodule Grizzly.ZWave.Notifications do
  @moduledoc """
  Encoding and decoding functions for notification events and types from the
  Notification command class.
  """

  alias Grizzly.ZWave.CommandClasses.NodeNaming
  alias Grizzly.ZWave.CommandClasses.UserCode
  alias Grizzly.ZWave.Commands.NodeLocationReport
  alias Grizzly.ZWave.Commands.UserCodeReport
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Decoder

  require Logger

  @type event :: atom()
  @type type :: atom()
  @type zwave_alarm_status :: :deactivate | :activate
  @type status :: :enabled | :disabled

  table = %{
    {0x01, :smoke_alarm} => %{
      0x00 => :state_idle,
      0x01 => :smoke_detected_location_provided,
      0x02 => :smoked_detected,
      0x03 => :smoke_alarm_test,
      0x04 => :replacement_required,
      0x05 => :replacement_required_end_of_life,
      0x06 => :alarm_silenced,
      0x07 => :maintenance_required_planned_periodic_inspection,
      0x08 => :maintenance_required_dust_in_device,
      0xFE => :unknown
    },
    {0x02, :co_alarm} => %{
      0x00 => :state_idle,
      0x01 => :co_detected_location_provided,
      0x02 => :co_detected,
      0x03 => :co_test,
      0x04 => :replacement_required,
      0x05 => :replacement_required_end_of_life,
      0x06 => :alarm_silenced,
      0x07 => :maintenance_required_planned_periodic_inspection,
      0xFE => :unknown
    },
    {0x03, :co2_alarm} => %{
      0x00 => :state_idle,
      0x01 => :co2_detected_location_provided,
      0x02 => :co2_detected,
      0x03 => :co2_test,
      0x04 => :replacement_required,
      0x05 => :replacement_required_end_of_life,
      0x06 => :alarm_silenced,
      0x07 => :maintenance_required_planned_periodic_inspection,
      0xFE => :unknown
    },
    {0x04, :heat_alarm} => %{
      0x00 => :state_idle,
      0x01 => :overheat_detected_location_provided,
      0x02 => :overheat_detected,
      0x03 => :rapid_temperature_rise_location_provided,
      0x04 => :rapid_temperature_rise,
      0x05 => :underheat_detected_location_provided,
      0x06 => :underheat_detected,
      0x07 => :heat_alarm_test,
      0x08 => :replacement_required_end_of_life,
      0x09 => :alarm_silenced,
      0x0A => :maintenance_required_dust_in_device,
      0x0B => :maintenance_required_planned_periodic_inspection,
      0x0C => :rapid_temperature_fall_location_provided,
      0x0D => :rapid_temperature_fall,
      0xFE => :unknown
    },
    {0x05, :water_alarm} => %{
      0x00 => :state_idle,
      0x01 => :water_leak_detected_location_provided,
      0x02 => :water_leak_detected,
      0x03 => :water_level_dropped_location_provided,
      0x04 => :water_level_dropped,
      0x05 => :replace_water_filter,
      0x06 => :water_flow_alarm,
      0x07 => :water_pressure_alarm,
      0x08 => :water_temperature_alarm,
      0x09 => :water_level_alarm,
      0x0A => :sump_pump_active,
      0x0B => :sump_pump_failure,
      0xFE => :unknown
    },
    {0x06, :access_control} => %{
      0x00 => :state_idle,
      0x01 => :manual_lock_operation,
      0x02 => :manual_unlock_operation,
      0x03 => :rf_lock_operation,
      0x04 => :rf_unlock_operation,
      0x05 => :keypad_lock_operation,
      0x06 => :keypad_unlock_operation,
      0x07 => :manual_not_fully_locked_operation,
      0x08 => :rf_not_fully_locked_operation,
      0x09 => :auto_lock_locked_operation,
      0x0A => :auto_lock_not_fully_locked_operation,
      0x0B => :lock_jammed,
      0x0C => :all_user_codes_deleted,
      0x0D => :single_user_code_deleted,
      0x0E => :new_user_code_added,
      0x0F => :new_user_code_not_added_duplicate,
      0x10 => :keypad_temporarily_disabled,
      0x11 => :keypad_busy,
      0x12 => :new_program_code_entered,
      0x13 => :manually_enter_user_code_exceeds_code_limit,
      0x14 => :unlock_by_rf_with_invalid_user_code,
      0x15 => :locked_by_rf_with_invalid_user_code,
      0x16 => :window_or_door_is_open,
      0x17 => :window_or_door_is_closed,
      0x18 => :window_or_door_handle_is_open,
      0x19 => :window_or_door_handle_is_closed,
      0x20 => :messaging_user_code_entered_via_keypad,
      0x21 => :lock_operation_with_user_code,
      0x22 => :unlock_operation_with_user_code,
      0x23 => :credential_lock_operation,
      0x24 => :credential_unlock_operation,
      0x25 => :all_users_deleted,
      0x26 => :multiple_credentials_deleted,
      0x27 => :user_added,
      0x28 => :user_modified,
      0x29 => :user_deleted,
      0x2A => :user_unchanged,
      0x2B => :credential_added,
      0x2C => :credential_modified,
      0x2D => :credential_deleted,
      0x2E => :credential_unchanged,
      0x2F => :valid_credential_denied_user_disabled,
      0x30 => :valid_credential_denied_user_schedule_not_active,
      0x31 => :user_access_denied_too_few_credentials,
      0x32 => :invalid_credential,
      0x33 => :non_access_credential_used,
      0x40 => :barrier_performing_initialization_process,
      0x41 => :barrier_operation_force_exceeded,
      0x42 => :barrier_operation_exceeded_time_limit,
      0x43 => :barrier_operation_exceeded_mechanical_limit,
      0x44 => :barrier_unable_to_perform_operation_ul_requirements,
      0x45 => :barrier_unattended_operation_disabled_ul_requirements,
      0x46 => :barrier_failed_operation_malfunction,
      0x47 => :barrier_vacation_mode,
      0x48 => :barrier_safety_beam_obstacle,
      0x49 => :barrier_sensor_not_detected,
      0x4A => :barrier_sensor_low_battery,
      0x4B => :barrier_short_in_wall_station_wires,
      0x4C => :barrier_associated_with_non_zwave_remote,
      0xFE => :unknown
    },
    {0x07, :home_security} => %{
      0x00 => :state_idle,
      0x01 => :intrusion_location_provided,
      0x02 => :intrusion,
      0x03 => :tampering_product_cover_removed,
      0x04 => :tampering_invalid_code,
      0x05 => :glass_breakage_location_provided,
      0x06 => :glass_breakage,
      0x07 => :motion_detection_location_provided,
      0x08 => :motion_detection,
      0x09 => :tampering_product_moved,
      0x0A => :impact_detected,
      0x0B => :magnetic_field_interface_detected,
      0x0C => :rf_jamming_detected,
      0xFE => :unknown
    },
    {0x08, :power_management} => %{
      0x00 => :state_idle,
      0x01 => :power_applied,
      0x02 => :ac_mains_disconnected,
      0x03 => :ac_mains_reconnected,
      0x04 => :surge_detected,
      0x05 => :voltage_drop,
      0x06 => :over_current_detected,
      0x07 => :over_voltage_detected,
      0x08 => :over_load_detected,
      0x09 => :load_error,
      0x0A => :replace_battery_soon,
      0x0B => :replace_battery_now,
      0x0C => :battery_is_charging,
      0x0D => :battery_is_fully_charged,
      0x0E => :charge_battery_soon,
      0x0F => :charge_battery_now,
      0x10 => :back_up_battery_low,
      0x11 => :battery_fluid_is_low,
      0x12 => :back_up_battery_disconnected,
      0x13 => :dc_connected,
      0x14 => :dc_disconnected,
      0xFE => :unknown
    },
    {0x09, :system} => %{
      0x00 => :state_idle,
      0x01 => :system_hardware_failure,
      0x02 => :system_software_failure,
      0x03 => :system_hardware_failure_code_provided,
      0x04 => :system_software_failure_code_provided,
      0x05 => :heartbeat,
      0x06 => :tampering_product_cover_removed,
      0x07 => :emergency_shutoff,
      0x08 => :undefined,
      0x09 => :digital_input_high_state,
      0x0A => :digital_input_low_state,
      0x0B => :digital_input_open,
      0xFE => :unknown
    },
    {0x0A, :emergency_alarm} => %{
      0x00 => :state_idle,
      0x01 => :contact_police,
      0x02 => :contact_fire_service,
      0x03 => :contact_medical_service,
      0x04 => :panic_alert,
      0xFE => :unknown
    },
    {0x0B, :clock} => %{
      0x00 => :state_idle,
      0x01 => :wake_up_alert,
      0x02 => :timer_ended,
      0x03 => :time_remaining,
      0xFE => :unknown
    },
    {0x0C, :appliance} => %{
      0x00 => :state_idle,
      0x01 => :program_started,
      0x02 => :program_in_progress,
      0x03 => :program_completed,
      0x04 => :replace_main_filter,
      0x05 => :failure_to_set_target_temperature,
      0x06 => :supplying_water,
      0x07 => :water_supply_failure,
      0x08 => :boiling,
      0x09 => :boiling_failure,
      0x0A => :washing,
      0x0B => :washing_failure,
      0x0C => :rinsing,
      0x0D => :rinsing_failure,
      0x0E => :draining,
      0x0F => :draining_failure,
      0x10 => :spinning,
      0x11 => :spinning_failure,
      0x12 => :drying,
      0x13 => :drying_failure,
      0x14 => :fan_failure,
      0x15 => :compressor_failure,
      0xFE => :unknown
    },
    {0x0D, :home_health} => %{
      0x00 => :state_idle,
      0x01 => :leaving_bed,
      0x02 => :sitting_on_bed,
      0x03 => :lying_on_bed,
      0x04 => :posture_changed,
      0x05 => :sitting_on_bed_edge,
      0x06 => :volatile_organic_compound_level,
      0x07 => :sleep_apnea_detected,
      0x08 => :sleep_stage_0_detected,
      0x09 => :sleep_stage_1_detected,
      0x0A => :sleep_stage_2_detected,
      0x0B => :sleep_stage_3_detected,
      0x0C => :fall_detected,
      0xFE => :unknown
    },
    {0x0E, :siren} => %{
      0x00 => :state_idle,
      0x01 => :state_active,
      0xFE => :unknown
    },
    {0x0F, :water_valve} => %{
      0x00 => :state_idle,
      0x01 => :valve_operation,
      0x02 => :main_valve_operation,
      0x03 => :valve_short_circuit,
      0x04 => :main_valve_short_circuit,
      0x05 => :valve_current_alarm,
      0x06 => :main_current_alarm,
      0x07 => :valve_jammed,
      0xFE => :unknown
    },
    {0x10, :weather_alarm} => %{
      0x00 => :state_idle,
      0x01 => :rain_alarm,
      0x02 => :moisture_alarm,
      0x03 => :freeze_alarm,
      0xFE => :unknown
    },
    {0x11, :irrigation} => %{
      0x00 => :state_idle,
      0x01 => :schedule_started,
      0x02 => :schedule_finished,
      0x03 => :valve_table_run_started,
      0x04 => :valve_table_run_finished,
      0x05 => :device_not_configured,
      0xFE => :unknown
    },
    {0x12, :gas_alarm} => %{
      0x00 => :state_idle,
      0x01 => :combustible_gas_detected_location_provided,
      0x02 => :combustible_gas_detected,
      0x03 => :toxic_gas_detected_location_provided,
      0x04 => :toxic_gas_detected,
      0x05 => :gas_alarm_test,
      0x06 => :replacement_required,
      0xFE => :unknown
    },
    {0x13, :pest_control} => %{
      0x00 => :state_idle,
      0x01 => :trap_armed_location_provided,
      0x02 => :trap_armed,
      0x03 => :trap_rearm_required_location_provided,
      0x04 => :trap_rearm_required,
      0x05 => :pest_detected_location_provided,
      0x06 => :pest_detected,
      0x07 => :pest_exterminated_location_provided,
      0x08 => :pest_exterminated,
      0xFE => :unknown
    },
    {0x14, :light_sensor} => %{
      0x00 => :state_idle,
      0x01 => :light_detected,
      0x02 => :light_color_transition_detected,
      0xFE => :unknown
    },
    {0x15, :water_quality_monitoring} => %{
      0x00 => :state_idle,
      0x01 => :chlorine_alarm,
      0x02 => :acidity_alarm,
      0x03 => :water_oxidation_alarm,
      0x04 => :chlorine_empty,
      0x05 => :acidity_empty,
      0x06 => :waterflow_measuring_station_shortage_detected,
      0x07 => :waterflow_clear_water_shortage_detected,
      0x08 => :disinfection_system_error_detected,
      0x09 => :filter_cleaning_ongoing,
      0x0A => :heating_operation_ongoing,
      0x0B => :filter_pump_operation_ongoing,
      0x0C => :freshwater_operation_ongoing,
      0x0D => :dry_protection_operation_active,
      0x0E => :water_tank_empty,
      0x0F => :water_tank_level_unknown,
      0x10 => :water_tank_full,
      0x11 => :collective_disorder,
      0xFE => :unknown
    },
    {0x16, :home_monitoring} => %{
      0x00 => :state_idle,
      0x01 => :home_occupied_location_provided,
      0x02 => :home_occupied,
      0xFE => :unknown
    }
  }

  @type_from_byte table |> Map.keys() |> Map.new()
  @type_to_byte table |> Map.keys() |> Map.new(fn {byte, type} -> {type, byte} end)

  @event_from_byte Map.new(table, fn {{_, type}, events} ->
                     {type, Map.new(events, fn {byte, event} -> {byte, event} end)}
                   end)

  @event_to_byte Map.new(table, fn {{_, type}, events} ->
                   {type, Map.new(events, fn {byte, event} -> {event, byte} end)}
                 end)

  @doc """
  Lists all notification types.
  """
  @spec all_notification_types() :: [atom()]
  def all_notification_types() do
    @type_from_byte |> Map.values()
  end

  @doc """
  Lists all events associated with the given notification type.
  """
  def all_events_by_type(type) do
    @event_from_byte |> Map.fetch!(type) |> Map.values()
  end

  @doc """
  Encode a notification type.
  """
  @spec type_to_byte(type()) :: byte()
  def type_to_byte(type) do
    case Map.fetch(@type_to_byte, type) do
      {:ok, byte} -> byte
      :error -> raise KeyError, "Unknown notification type: #{inspect(type)}"
    end
  end

  @doc """
  Encode a notification event.
  """
  @spec event_to_byte(type(), event()) :: byte()
  # :state_idle is always encoded as 0x00 no matter the type
  def event_to_byte(_type, :state_idle), do: 0x00

  def event_to_byte(type, event) do
    with nil <- get_in(@event_to_byte, [type, event]) do
      raise KeyError, "Unknown notification event: #{inspect(type)} / #{inspect(event)}"
    end
  end

  @doc """
  Decode a notification type.
  """
  @spec type_from_byte(byte()) :: {:ok, type()} | {:error, :invalid_type_byte}
  def type_from_byte(byte) do
    case Map.fetch(@type_from_byte, byte) do
      {:ok, type} -> {:ok, type}
      # There is no decoding for Alarm CC V1 - the byte is the type
      :error -> {:error, :invalid_type_byte}
    end
  end

  @doc """
  Decode a notification event.
  """
  @spec event_from_byte(type(), byte()) :: {:ok, event()} | {:error, :invalid_event_byte}
  # Event 0x00 is always :state_idle even if the type is not known
  def event_from_byte(_type, 0), do: {:ok, :state_idle}

  def event_from_byte(type, byte) do
    with v when not is_nil(v) <- get_in(@event_from_byte, [type, byte]) do
      {:ok, v}
    else
      # Alarm reports might not provide a defined event (e.g.  event byte is 0)
      _ -> {:error, :invalid_event_byte}
    end
  end

  @spec status_to_byte(status()) :: 0x00 | 0xFF
  def status_to_byte(:disabled), do: 0x00
  def status_to_byte(:enabled), do: 0xFF

  @spec status_from_byte(byte()) :: {:ok, status()} | {:error, :invalid_status_byte}
  def status_from_byte(0x00), do: {:ok, :disabled}
  def status_from_byte(0xFF), do: {:ok, :enabled}
  def status_from_byte(_byte), do: {:error, :invalid_status_byte}

  def encode_event_params(_zwave_type, _zwave_event, []), do: <<>>

  def encode_event_params(:access_control, zwave_event, event_params_list)
      when zwave_event in [:keypad_lock_operation, :keypad_unlock_operation, :new_user_code_added] do
    {:ok, user_code_report} = UserCodeReport.new(event_params_list)

    <<UserCode.byte(), user_code_report.command_byte>> <>
      UserCodeReport.encode_params(user_code_report)
  end

  def encode_event_params(:home_security, zwave_event, event_params_list)
      when zwave_event in [
             :intrusion_location_provided,
             :glass_breakage_location_provided,
             :motion_detection_location_provided
           ] do
    {:ok, node_location_report} = NodeLocationReport.new(event_params_list)

    <<NodeNaming.byte(), node_location_report.command_byte>> <>
      NodeLocationReport.encode_params(node_location_report)
  end

  def encode_event_params(:smoke_alarm, :smoke_detected_location_provided, event_params_list) do
    {:ok, node_location_report} = NodeLocationReport.new(event_params_list)

    <<NodeNaming.byte(), node_location_report.command_byte>> <>
      NodeLocationReport.encode_params(node_location_report)
  end

  def encode_event_params(:water_alarm, zwave_event, event_params_list)
      when zwave_event in [
             :water_leak_detected_location_provided,
             :water_level_dropped_location_provided
           ] do
    {:ok, node_location_report} = NodeLocationReport.new(event_params_list)

    <<NodeNaming.byte(), node_location_report.command_byte>> <>
      NodeLocationReport.encode_params(node_location_report)
  end

  def encode_event_params(zwave_type, zwave_event, event_params) do
    Logger.info(
      "[Grizzly] Encoding not implemented for event params #{inspect(event_params)} for zwave_type #{inspect(zwave_type)} and zwave_event #{inspect(zwave_event)}"
    )

    <<>>
  end

  def decode_event_params(zwave_type, zwave_event, <<>>) do
    Logger.info(
      "[Grizzly] No event parameters for #{inspect(zwave_type)} #{inspect(zwave_event)}"
    )

    {:ok, []}
  end

  # Some locks do not encode an encapsulated UserCodeReport as event parameters; they only give the user id
  def decode_event_params(:access_control, zwave_event, <<user_id>>)
      when zwave_event in [:keypad_lock_operation, :keypad_unlock_operation] do
    {:ok,
     [
       user_id: user_id,
       user_id_status: :status_not_available,
       user_code: ""
     ]}
  end

  def decode_event_params(:access_control, zwave_event, params_binary)
      when zwave_event in [:keypad_lock_operation, :keypad_unlock_operation] do
    with {:ok, user_code_report} <- Decoder.from_binary(params_binary) do
      {:ok, user_code_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warning("[Grizzly] Failed to decode UserCodeReport from #{inspect(params_binary)}")
        decode_error
    end
  end

  def decode_event_params(:home_security, zwave_event, params_binary)
      when zwave_event in [
             :intrusion_location_provided,
             :glass_breakage_location_provided,
             :motion_detection_location_provided
           ] do
    with {:ok, node_location_report} <- Decoder.from_binary(params_binary) do
      {:ok, node_location_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warning(
          "[Grizzly] Failed to decode NodeLocationReport from #{inspect(params_binary)}"
        )

        decode_error
    end
  end

  def decode_event_params(notification_type, :state_idle, <<byte::8>>) do
    case event_from_byte(notification_type, byte) do
      {:ok, event} ->
        {:ok, [state: event]}

      {:error, :invalid_event_byte} ->
        Logger.warning(
          "[Grizzly] Failed to decode state variable from #{inspect(notification_type)} state_idle event"
        )

        {:ok, []}
    end
  end

  def decode_event_params(:water_alarm, zwave_event, params_binary)
      when zwave_event in [
             :water_leak_detected_location_provided,
             :water_level_dropped_location_provided
           ] do
    with {:ok, node_location_report} <- Decoder.from_binary(params_binary) do
      {:ok, node_location_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warning(
          "[Grizzly] Failed to decode NodeLocationReport from #{inspect(params_binary)}"
        )

        decode_error
    end
  end

  def decode_event_params(:smoke_alarm, :smoke_detected_location_provided, params_binary) do
    with {:ok, node_location_report} <- Decoder.from_binary(params_binary) do
      {:ok, node_location_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warning(
          "[Grizzly] Failed to decode NodeLocationReport from #{inspect(params_binary)}"
        )

        decode_error
    end
  end

  def decode_event_params(zwave_type, zwave_event, params_binary) do
    Logger.info(
      "Decoding not implemented for event params #{inspect(params_binary)} for zwave_type #{inspect(zwave_type)} and zwave_event #{inspect(zwave_event)}"
    )

    {:ok, [raw: :erlang.binary_to_list(params_binary)]}
  end
end
