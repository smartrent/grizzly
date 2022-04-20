defmodule Grizzly.ZWave.Notifications do
  alias Grizzly.ZWave.Commands.{UserCodeReport, NodeLocationReport}
  alias Grizzly.ZWave.CommandClasses.{UserCode, NodeNaming}
  alias Grizzly.ZWave.{Decoder, DecodeError}
  require Logger

  @alarm_types [
    # Byte 1
    [
      :unknown,
      :smoke_alarm,
      :co_alarm,
      :co2_alarm,
      :heat_alarm,
      :water_alarm,
      :access_control,
      :home_security
    ],
    # Byte 2
    [
      :power_management,
      :system,
      :emergency_alarm,
      :clock,
      :appliance,
      :home_health,
      :siren,
      :water_valve
    ],
    # Byte 3
    [
      :weather_alarm,
      :irrigation,
      :gas_alarm,
      :pest_control,
      :light_sensor,
      :water_quality_monitoring,
      :home_monitoring,
      :request_pending_notification
    ]
  ]

  @type_events [
    smoke_alarm: [
      # byte 1
      [
        :state_idle,
        :smoke_detected_location_provided,
        :smoked_detected,
        :smoke_alarm_test,
        :replacement_required,
        :replacement_required_end_of_life,
        :alarm_silenced,
        :maintenance_required_planned_periodic_inspection
      ],
      # byte 2
      [
        :maintenance_required_dust_in_device,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    co_alarm: [
      # byte 1
      [
        :state_idle,
        :co_detected_location_provided,
        :co_detected,
        :co_test,
        :replacement_required,
        :replacement_required_end_of_life,
        :alarm_silenced,
        :maintenance_required_planned_periodic_inspection
      ]
    ],
    co2_alarm: [
      # byte 1
      [
        :state_idle,
        :co2_detected_location_provided,
        :co2_detected,
        :co2_test,
        :replacement_required,
        :replacement_required_end_of_life,
        :alarm_silenced,
        :maintenance_required_planned_periodic_inspection
      ]
    ],
    heat_alarm: [
      # byte 1
      [
        :state_idle,
        :overheat_detected_location_provided,
        :overheat_detected,
        :rapid_temperature_rise_location_provided,
        :rapid_temperature_rise,
        :underheat_detected_location_provided,
        :underheat_detected,
        :heat_alarm_test
      ],
      # byte 2
      [
        :replacement_required_end_of_life,
        :alarm_silenced,
        :maintenance_required_dust_in_device,
        :maintenance_required_planned_periodic_inspection,
        :rapid_temperature_fall_location_provided,
        :rapid_temperature_fall,
        :unknown,
        :unknown
      ]
    ],
    water_alarm: [
      # byte 1
      [
        :state_idle,
        :water_leak_detected_location_provided,
        :water_leak_detected,
        :water_level_dropped_location_provided,
        :water_level_dropped,
        :replace_water_filter,
        :water_flow_alarm,
        :water_pressure_alarm
      ],
      # byte 2
      [
        :water_temperature_alarm,
        :water_level_alarm,
        :sump_pump_active,
        :sump_pump_failure,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    access_control: [
      # byte 1
      [
        :state_idle,
        :manual_lock_operation,
        :manual_unlock_operation,
        :rf_lock_operation,
        :rf_unlock_operation,
        :keypad_lock_operation,
        :keypad_unlock_operation,
        :manual_not_fully_locked_operation
      ],
      # byte 2
      [
        :rf_not_fully_locked_operation,
        :auto_lock_locked_operation,
        :auto_lock_not_fully_locked_operation,
        :lock_jammed,
        :all_user_codes_deleted,
        :single_user_code_deleted,
        :new_user_code_added,
        :new_user_code_not_added_duplicate
      ],
      # byte 3
      [
        :keypad_temporarily_disabled,
        :keypad_busy,
        :new_program_code_entered,
        :manually_enter_user_code_exceeds_code_limit,
        :unlock_by_rf_with_invalid_user_code,
        :locked_by_rf_with_invalid_user_code,
        :window_or_door_is_open,
        :window_or_door_is_closed
      ],
      # byte 4
      [
        :window_or_door_handle_is_open,
        :window_or_door_handle_is_closed,
        :messaging_user_code_entered_via_keypad,
        :barrier_performing_initialization_process,
        :barrier_operation_exceeded_time_limit,
        :barrier_operation_force_exceeded,
        :barrier_operation_exceeded_mechanical_limit,
        :barrier_unable_to_perform_operation_ul_requirements
      ],
      # byte 5
      [
        :barrier_unattended_operation_disabled_ul_requirements,
        :barrier_failed_operation_malfunction,
        :barrier_vacation_mode,
        :barrier_safety_beam_obstacle,
        :barrier_sensor_not_detected,
        :barrier_sensor_low_battery,
        :barrier_short_in_wall_station_wires,
        :unknown
      ]
    ],
    home_security: [
      # byte 1
      [
        :state_idle,
        :intrusion_location_provided,
        :intrusion,
        :tampering_product_cover_removed,
        :tampering_invalid_code,
        :glass_breakage_location_provided,
        :glass_breakage,
        :motion_detection_location_provided
      ],
      # byte 2
      [
        :motion_detection,
        :tampering_product_moved,
        :impact_detected,
        :magnetic_field_interface_detected,
        :rf_jamming_detected,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    power_management: [
      # byte 1
      [
        :state_idle,
        :power_applied,
        :ac_mains_disconnected,
        :ac_mains_reconnected,
        :surge_detected,
        :voltage_drop,
        :over_current_detected,
        :over_voltage_detected
      ],
      # byte 2
      [
        :over_load_detected,
        :load_error,
        :replace_battery_soon,
        :replace_battery_now,
        :battery_is_charging,
        :battery_is_fully_charged,
        :charge_battery_soon,
        :charge_battery_now
      ],
      # byte 3
      [
        :back_up_battery_low,
        :battery_fluid_is_low,
        :back_up_battery_disconnected,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    system: [
      # byte 1
      [
        :state_idle,
        :system_hardware_failure,
        :system_software_failure,
        :system_hardware_failure_code_provided,
        :system_software_failure_code_provided,
        :heartbeat,
        :tampering_product_cover_removed,
        :emergency_shutoff
      ],
      # byte 2
      [
        :undefined,
        :digital_input_high_state,
        :digital_input_low_state,
        :digital_input_open,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    emergency_alarm: [
      # byte 1
      :state_idle,
      :contact_police,
      :contact_fire_service,
      :contact_medical_service,
      :panic_alert,
      :unknown,
      :unknown,
      :unknown
    ],
    clock: [
      # byte 1
      :state_idle,
      :wake_up_alert,
      :time_ended,
      :time_remaining,
      :unknown,
      :unknown,
      :unknown,
      :unknown
    ],
    appliance: [
      # byte 1
      [
        :state_idle,
        :program_started,
        :program_in_progress,
        :program_completed,
        :replace_main_filter,
        :failure_to_set_target_temperature,
        :supplying_water,
        :water_supply_failure
      ],
      # byte 2
      [
        :boiling,
        :boiling_failure,
        :washing,
        :washing_failure,
        :rinsing,
        :rinsing_failure,
        :draining,
        :draining_failure
      ],
      # byte 3
      [
        :spinning,
        :spinning_failure,
        :drying,
        :drying_failure,
        :fan_failure,
        :compressor_failure,
        :unknown,
        :unknown
      ]
    ],
    home_health: [
      # byte 1
      [
        :state_idle,
        :leaving_bed,
        :sitting_on_bed,
        :lying_on_bed,
        :posture_changed,
        :sitting_on_bed_edge,
        # patient is hitting the bottle
        :volatile_organic_compound_level,
        :sleep_apnea_detected
      ],
      # byte 2
      [
        :sleep_stage_0_detected,
        :sleep_stage_1_detected,
        :sleep_stage_2_detected,
        :sleep_stage_3_detected,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    siren: [
      # byte 1
      [
        :state_idle,
        :state_active,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    water_valve: [
      # byte 1
      [
        :state_idle,
        :valve_operation,
        :master_valve_operation,
        :valve_short_circuit,
        :master_valve_short_circuit,
        :master_valve_current_alarm,
        :unknown,
        :unknown
      ]
    ],
    weather_alarm: [
      # byte 1
      [
        :state_idle,
        :rain_alarm,
        :moisture_alarm,
        :freeze_alarm,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    irrigation: [
      # byte 1
      [
        :state_idle,
        :schedule_started,
        :schedule_finished,
        :valve_table_run_started,
        :valve_table_run_finished,
        :device_not_configured,
        :unknown,
        :unknown
      ]
    ],
    gas_alarm: [
      # byte 1
      [
        :state_idle,
        :combustible_gas_detected_location_provided,
        :combustible_gas_detected,
        :toxic_gas_detected_location_provided,
        :toxic_gas_detected,
        :gas_alarm_test,
        :replacement_required,
        :unknown
      ]
    ],
    pest_control: [
      # byte 1
      [
        :state_idle,
        :trap_armed_location_provided,
        :trap_armed,
        :trap_rearm_required_location_provided,
        :trap_rearm_required,
        :pest_detected_location_provided,
        :pest_detected,
        :pest_exterminated_location_provided
      ],
      # byte 2
      [
        :pest_exterminated,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    light_sensor: [
      # byte 1
      [
        :state_idle,
        :light_detected,
        :light_color_transition_detected,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    water_quality_monitoring: [
      # byte 1
      [
        :state_idle,
        :chlorine_alarm,
        :acidity_alarm,
        :water_oxidation_alarm,
        :chlorine_empty,
        :acidity_empty,
        :waterflow_measuring_station_shortage_detected,
        :waterflow_clear_water_shortage_detected
      ],
      # byte 2
      [
        :disinfection_system_error_detected,
        :filter_cleaning_ongoing,
        :heating_operation_ongoing,
        :filter_pump_operation_ongoing,
        :freshwater_operation_ongoing,
        :dry_protection_operation_active,
        :water_tank_empty,
        :water_tank_level_unknown
      ],
      # byte 3
      [
        :water_tank_full,
        :collective_disorder,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ],
    home_monitoring: [
      # byte 1
      [
        :state_idle,
        :home_occupied_location_provided,
        :home_occupied,
        :unknown,
        :unknown,
        :unknown,
        :unknown,
        :unknown
      ]
    ]
  ]

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
      {0x01, :smoke_alarm, 0xFE, :unknown},

      # CO Alarm (0x02)
      {0x02, :co_alarm, 0x00, :state_idle},
      {0x02, :co_alarm, 0x01, :co_detected_location_provided},
      {0x02, :co_alarm, 0x02, :co_detected},
      {0x02, :co_alarm, 0x03, :co_test},
      {0x02, :co_alarm, 0x04, :replacement_required},
      {0x02, :co_alarm, 0x05, :replacement_required_end_of_life},
      {0x02, :co_alarm, 0x06, :alarm_silenced},
      {0x02, :co_alarm, 0x07, :maintenance_required_planned_periodic_inspection},
      {0x02, :co_alarm, 0xFE, :unknown},

      # CO2 Alarm (0x03)
      {0x03, :co2_alarm, 0x00, :state_idle},
      {0x03, :co2_alarm, 0x01, :co2_detected_location_provided},
      {0x03, :co2_alarm, 0x02, :co2_detected},
      {0x03, :co2_alarm, 0x03, :co2_test},
      {0x03, :co2_alarm, 0x04, :replacement_required},
      {0x03, :co2_alarm, 0x05, :replacement_required_end_of_life},
      {0x03, :co2_alarm, 0x06, :alarm_silenced},
      {0x03, :co2_alarm, 0x07, :maintenance_required_planned_periodic_inspection},
      {0x03, :co2_alarm, 0xFE, :unknown},

      # Heat Alarm (0x04)
      {0x04, :heat_alarm, 0x00, :state_idle},
      {0x04, :heat_alarm, 0x01, :overheat_detected_location_provided},
      {0x04, :heat_alarm, 0x02, :overheat_detected},
      {0x04, :heat_alarm, 0x03, :rapid_temperature_rise_location_provided},
      {0x04, :heat_alarm, 0x04, :rapid_temperature_rise},
      {0x04, :heat_alarm, 0x05, :underheat_detected_location_provided},
      {0x04, :heat_alarm, 0x06, :underheat_detected},
      {0x04, :heat_alarm, 0x07, :heat_alarm_test},
      {0x04, :heat_alarm, 0x08, :replacement_required_end_of_life},
      {0x04, :heat_alarm, 0x09, :alarm_silenced},
      {0x04, :heat_alarm, 0x0A, :maintenance_required_dust_in_device},
      {0x04, :heat_alarm, 0x0B, :maintenance_required_planned_periodic_inspection},
      {0x04, :heat_alarm, 0x0C, :rapid_temperature_fall_location_provided},
      {0x04, :heat_alarm, 0x0D, :rapid_temperature_fall},
      {0x04, :heat_alarm, 0xFE, :unknown},

      # Water (0x05)
      {0x05, :water_alarm, 0x00, :state_idle},
      {0x05, :water_alarm, 0x01, :water_leak_detected_location_provided},
      {0x05, :water_alarm, 0x02, :water_leak_detected},
      {0x05, :water_alarm, 0x03, :water_level_dropped_location_provided},
      {0x05, :water_alarm, 0x04, :water_level_dropped},
      {0x05, :water_alarm, 0x05, :replace_water_filter},
      {0x05, :water_alarm, 0x06, :water_flow_alarm},
      {0x05, :water_alarm, 0x07, :water_pressure_alarm},
      {0x05, :water_alarm, 0x08, :water_temperature_alarm},
      {0x05, :water_alarm, 0x09, :water_level_alarm},
      {0x05, :water_alarm, 0x0A, :sump_pump_active},
      {0x05, :water_alarm, 0x0B, :sump_pump_failure},
      {0x05, :water_alarm, 0xFE, :unknown},

      # Access Control (0x06)
      {0x06, :access_control, 0x00, :state_idle},
      {0x06, :access_control, 0x01, :manual_lock_operation},
      {0x06, :access_control, 0x02, :manual_unlock_operation},
      {0x06, :access_control, 0x03, :rf_lock_operation},
      {0x06, :access_control, 0x04, :rf_unlock_operation},
      {0x06, :access_control, 0x05, :keypad_lock_operation},
      {0x06, :access_control, 0x06, :keypad_unlock_operation},
      {0x06, :access_control, 0x07, :manual_not_fully_locked_operation},
      {0x06, :access_control, 0x08, :rf_not_fully_locked_operation},
      {0x06, :access_control, 0x09, :auto_lock_locked_operation},
      {0x06, :access_control, 0x0A, :auto_lock_not_fully_locked_operation},
      {0x06, :access_control, 0x0B, :lock_jammed},
      {0x06, :access_control, 0x0C, :all_user_codes_deleted},
      {0x06, :access_control, 0x0D, :single_user_code_deleted},
      {0x06, :access_control, 0x0E, :new_user_code_added},
      {0x06, :access_control, 0x0F, :new_user_code_not_added_duplicate},
      {0x06, :access_control, 0x10, :keypad_temporarily_disabled},
      {0x06, :access_control, 0x11, :keypad_busy},
      {0x06, :access_control, 0x12, :new_program_code_entered},
      {0x06, :access_control, 0x13, :manually_enter_user_code_exceeds_code_limit},
      {0x06, :access_control, 0x14, :unlock_by_rf_with_invalid_user_code},
      {0x06, :access_control, 0x15, :locked_by_rf_with_invalid_user_code},
      {0x06, :access_control, 0x16, :window_or_door_is_open},
      {0x06, :access_control, 0x17, :window_or_door_is_closed},
      {0x06, :access_control, 0x18, :window_or_door_handle_is_open},
      {0x06, :access_control, 0x19, :window_or_door_handle_is_closed},
      {0x06, :access_control, 0x20, :messaging_user_code_entered_via_keypad},
      {0x06, :access_control, 0x40, :barrier_performing_initialization_process},
      {0x06, :access_control, 0x41, :barrier_operation_exceeded_time_limit},
      {0x06, :access_control, 0x42, :barrier_operation_force_exceeded},
      {0x06, :access_control, 0x43, :barrier_operation_exceeded_mechanical_limit},
      {0x06, :access_control, 0x44, :barrier_unable_to_perform_operation_ul_requirements},
      {0x06, :access_control, 0x45, :barrier_unattended_operation_disabled_ul_requirements},
      {0x06, :access_control, 0x46, :barrier_failed_operation_malfunction},
      {0x06, :access_control, 0x47, :barrier_vacation_mode},
      {0x06, :access_control, 0x48, :barrier_safety_beam_obstacle},
      {0x06, :access_control, 0x49, :barrier_sensor_not_detected},
      {0x06, :access_control, 0x4A, :barrier_sensor_low_battery},
      {0x06, :access_control, 0x4B, :barrier_short_in_wall_station_wires},
      {0x06, :access_control, 0xFE, :unknown},

      # # Home Security (0x07)
      {0x07, :home_security, 0x00, :state_idle},
      {0x07, :home_security, 0x01, :intrusion_location_provided},
      {0x07, :home_security, 0x02, :intrusion},
      {0x07, :home_security, 0x03, :tampering_product_cover_removed},
      {0x07, :home_security, 0x04, :tampering_invalid_code},
      {0x07, :home_security, 0x05, :glass_breakage_location_provided},
      {0x07, :home_security, 0x06, :glass_breakage},
      {0x07, :home_security, 0x07, :motion_detection_location_provided},
      {0x07, :home_security, 0x08, :motion_detection},
      {0x07, :home_security, 0x09, :tampering_product_moved},
      {0x07, :home_security, 0x0A, :impact_detected},
      {0x07, :home_security, 0x0B, :magnetic_field_interface_detected},
      {0x07, :home_security, 0xFE, :unknown},

      # # Power Management (0x08)
      {0x08, :power_management, 0x00, :state_idle},
      {0x08, :power_management, 0x01, :power_applied},
      {0x08, :power_management, 0x02, :ac_mains_disconnected},
      {0x08, :power_management, 0x03, :ac_mains_reconnected},
      {0x08, :power_management, 0x04, :surge_detected},
      {0x08, :power_management, 0x05, :voltage_drop},
      {0x08, :power_management, 0x06, :over_current_detected},
      {0x08, :power_management, 0x07, :over_voltage_detected},
      {0x08, :power_management, 0x08, :over_load_detected},
      {0x08, :power_management, 0x09, :load_error},
      {0x08, :power_management, 0x0A, :replace_battery_soon},
      {0x08, :power_management, 0x0B, :replace_battery_now},
      {0x08, :power_management, 0x0C, :battery_is_charging},
      {0x08, :power_management, 0x0D, :battery_is_fully_charged},
      {0x08, :power_management, 0x0E, :charge_battery_soon},
      {0x08, :power_management, 0x0F, :charge_battery_now},
      {0x08, :power_management, 0x10, :back_up_battery_low},
      {0x08, :power_management, 0x11, :battery_fluid_is_low},
      {0x08, :power_management, 0x12, :back_up_battery_disconnected},
      {0x08, :power_management, 0xFE, :unknown},

      # System (0x09)
      {0x09, :system, 0x00, :state_idle},
      {0x09, :system, 0x01, :system_hardware_failure},
      {0x09, :system, 0x02, :system_software_failure},
      {0x09, :system, 0x03, :system_hardware_failure_code_provided},
      {0x09, :system, 0x04, :system_software_failure_code_provided},
      {0x09, :system, 0x05, :heartbeat},
      {0x09, :system, 0x06, :tampering_product_cover_removed},
      {0x09, :system, 0x07, :emergency_shutoff},
      {0x09, :system, 0x08, :undefined},
      {0x09, :system, 0x09, :digital_input_high_state},
      {0x09, :system, 0x0A, :digital_input_low_state},
      {0x09, :system, 0x0B, :digital_input_open},
      {0x09, :system, 0xFE, :unknown},

      # Emergency Alarm (0x0A)
      {0x0A, :emergency_alarm, 0x00, :state_idle},
      {0x0A, :emergency_alarm, 0x01, :co2_detected_location_provided},
      {0x0A, :emergency_alarm, 0x02, :co2_detected},
      {0x0A, :emergency_alarm, 0x03, :co2_test},
      {0x0A, :emergency_alarm, 0x04, :replacement_required},
      {0x0A, :emergency_alarm, 0x05, :replacement_required_end_of_life},
      {0x0A, :emergency_alarm, 0x06, :alarm_silenced},
      {0x0A, :emergency_alarm, 0x07, :maintenance_required_planned_periodic_inspection},

      # Clock (0x0B)
      {0x0B, :clock, 0x00, :state_idle},
      {0x0B, :clock, 0x01, :wake_up_alert},
      {0x0B, :clock, 0x02, :time_ended},
      {0x0B, :clock, 0x03, :time_remaining},
      {0x0B, :clock, 0xFE, :unknown},

      # Appliance (0x0C)
      {0x0C, :appliance, 0x00, :state_idle},
      {0x0C, :appliance, 0x01, :program_started},
      {0x0C, :appliance, 0x02, :program_in_progress},
      {0x0C, :appliance, 0x03, :program_completed},
      {0x0C, :appliance, 0x04, :replace_main_filter},
      {0x0C, :appliance, 0x05, :failure_to_set_target_temperature},
      {0x0C, :appliance, 0x06, :supplying_water},
      {0x0C, :appliance, 0x07, :water_supply_failure},
      {0x0C, :appliance, 0x08, :boiling},
      {0x0C, :appliance, 0x09, :boiling_failure},
      {0x0C, :appliance, 0x0A, :washing},
      {0x0C, :appliance, 0x0B, :washing_failure},
      {0x0C, :appliance, 0x0C, :rinsing},
      {0x0C, :appliance, 0x0D, :rinsing_failure},
      {0x0C, :appliance, 0x0E, :draining},
      {0x0C, :appliance, 0x0F, :draining_failure},
      {0x0C, :appliance, 0x10, :spinning},
      {0x0C, :appliance, 0x11, :spinning_failure},
      {0x0C, :appliance, 0x12, :drying},
      {0x0C, :appliance, 0x13, :drying_failure},
      {0x0C, :appliance, 0x14, :fan_failure},
      {0x0C, :appliance, 0x15, :compressor_failure},
      {0x0C, :appliance, 0xFE, :unknown},

      # Home health (0x0D)
      {0x0D, :home_health, 0x00, :state_idle},
      {0x0D, :home_health, 0x01, :leaving_bed},
      {0x0D, :home_health, 0x02, :sitting_on_bed},
      {0x0D, :home_health, 0x03, :lying_on_bed},
      {0x0D, :home_health, 0x04, :posture_changed},
      {0x0D, :home_health, 0x05, :sitting_on_bed_edge},
      {0x0D, :home_health, 0x06, :volatile_organic_compound_level},
      {0x0D, :home_health, 0x07, :sleep_apnea_detected},
      {0x0D, :home_health, 0x08, :sleep_stage_0_detected},
      {0x0D, :home_health, 0x09, :sleep_stage_1_detected},
      {0x0D, :home_health, 0x0A, :sleep_stage_2_detected},
      {0x0D, :home_health, 0x0B, :sleep_stage_3_detected},
      {0x0D, :home_health, 0xFE, :unknown},

      # Siren (0x0E)
      {0x0E, :siren, 0x00, :state_idle},
      {0x0E, :siren, 0x01, :state_active},
      {0x0E, :siren, 0xFE, :unknown},

      # Water valve (0x0F)
      {0x0F, :water_valve, 0x00, :state_idle},
      {0x0F, :water_valve, 0x01, :valve_operation},
      {0x0F, :water_valve, 0x02, :master_valve_operation},
      {0x0F, :water_valve, 0x03, :valve_short_circuit},
      {0x0F, :water_valve, 0x04, :master_valve_short_circuit},
      {0x0F, :water_valve, 0x05, :master_valve_current_alarm},
      {0x0F, :water_valve, 0xFE, :unknown},

      # Weather alarm (0x10)
      {0x10, :weather_alarm, 0x00, :state_idle},
      {0x10, :weather_alarm, 0x01, :rain_alarm},
      {0x10, :weather_alarm, 0x02, :moisture_alarm},
      {0x10, :weather_alarm, 0x03, :freeze_alarm},
      {0x10, :weather_alarm, 0xFE, :unknown},

      # Irrigation (0x11)
      {0x11, :irrigation, 0x00, :state_idle},
      {0x11, :irrigation, 0x01, :schedule_started},
      {0x11, :irrigation, 0x02, :schedule_finished},
      {0x11, :irrigation, 0x03, :valve_table_run_started},
      {0x11, :irrigation, 0x04, :valve_table_run_finished},
      {0x11, :irrigation, 0x05, :device_not_configured},
      {0x11, :irrigation, 0xFE, :unknown},

      # Gas alarm (0x12)
      {0x12, :gas_alarm, 0x00, :state_idle},
      {0x12, :gas_alarm, 0x01, :combustible_gas_detected_location_provided},
      {0x12, :gas_alarm, 0x02, :combustible_gas_detected},
      {0x12, :gas_alarm, 0x03, :toxic_gas_detected_location_provided},
      {0x12, :gas_alarm, 0x04, :toxic_gas_detected},
      {0x12, :gas_alarm, 0x05, :gas_alarm_test},
      {0x12, :gas_alarm, 0x06, :replacement_required},
      {0x12, :gas_alarm, 0xFE, :unknown},

      # Pest control (0x13)
      {0x13, :pest_contol, 0x00, :state_idle},
      {0x13, :pest_contol, 0x01, :trap_armed_location_provided},
      {0x13, :pest_contol, 0x02, :trap_armed},
      {0x13, :pest_contol, 0x03, :trap_rearm_required_location_provided},
      {0x13, :pest_contol, 0x04, :trap_rearm_required},
      {0x13, :pest_contol, 0x05, :pest_detected_location_provided},
      {0x13, :pest_contol, 0x06, :pest_detected},
      {0x13, :pest_contol, 0x07, :pest_exterminated_location_provided},
      {0x13, :pest_contol, 0x08, :pest_exterminated},
      {0x13, :pest_contol, 0xFE, :unknown},

      # Light sensor (0x14)
      {0x14, :light_sensor, 0x00, :state_idle},
      {0x14, :light_sensor, 0x01, :light_detected},
      {0x14, :light_sensor, 0x02, :light_color_transition_detected},
      {0x14, :light_sensor, 0xFE, :unknown},

      # Water quality monitoring (0x15)
      {0x15, :water_quality_monitoring, 0x00, :state_idle},
      {0x15, :water_quality_monitoring, 0x01, :chlorine_alarm},
      {0x15, :water_quality_monitoring, 0x02, :acidity_alarm},
      {0x15, :water_quality_monitoring, 0x03, :water_oxidation_alarm},
      {0x15, :water_quality_monitoring, 0x04, :chlorine_empty},
      {0x15, :water_quality_monitoring, 0x05, :acidity_empty},
      {0x15, :water_quality_monitoring, 0x06, :waterflow_measuring_station_shortage_detected},
      {0x15, :water_quality_monitoring, 0x07, :waterflow_clear_water_shortage_detected},
      {0x15, :water_quality_monitoring, 0x08, :disinfection_system_error_detected},
      {0x15, :water_quality_monitoring, 0x09, :filter_cleaning_ongoing},
      {0x15, :water_quality_monitoring, 0x0A, :heating_operation_ongoing},
      {0x15, :water_quality_monitoring, 0x0B, :filter_pump_operation_ongoing},
      {0x15, :water_quality_monitoring, 0x0C, :freshwater_operation_ongoing},
      {0x15, :water_quality_monitoring, 0x0D, :dry_protection_operation_active},
      {0x15, :water_quality_monitoring, 0x0E, :water_tank_empty},
      {0x15, :water_quality_monitoring, 0x0F, :water_tank_level_unknown},
      {0x15, :water_quality_monitoring, 0x10, :water_tank_full},
      {0x15, :water_quality_monitoring, 0x11, :collective_disorder},
      {0x15, :water_quality_monitoring, 0xFE, :unknown},

      # Home monitoring (0x16)
      {0x16, :home_monitoring, 0x00, :state_idle},
      {0x16, :home_monitoring, 0x01, :home_occupied_location_provided},
      {0x16, :home_monitoring, 0x02, :home_occupied},
      {0x16, :home_monitoring, 0xFE, :unknown}
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
             :water_level_droppped_location_provided
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
       user_code: 0
     ]}
  end

  def decode_event_params(:access_control, zwave_event, params_binary)
      when zwave_event in [:keypad_lock_operation, :keypad_unlock_operation] do
    with {:ok, user_code_report} <- Decoder.from_binary(params_binary) do
      {:ok, user_code_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warn("[Grizzly] Failed to decode UserCodeReport from #{inspect(params_binary)}")
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
        Logger.warn(
          "[Grizzly] Failed to decode NodeLocationReport from #{inspect(params_binary)}"
        )

        decode_error
    end
  end

  def decode_event_params(:water_alarm, zwave_event, params_binary)
      when zwave_event in [
             :water_leak_detected_location_provided,
             :water_level_droppped_location_provided
           ] do
    with {:ok, node_location_report} <- Decoder.from_binary(params_binary) do
      {:ok, node_location_report.params}
    else
      {:error, %DecodeError{}} = decode_error ->
        Logger.warn(
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
        Logger.warn(
          "[Grizzly] Failed to decode NodeLocationReport from #{inspect(params_binary)}"
        )

        decode_error
    end
  end

  def decode_event_params(zwave_type, zwave_event, params_binary) do
    Logger.info(
      "Decoding not implemented for event params #{inspect(params_binary)} for zwave_type #{inspect(zwave_type)} and zwave_event #{inspect(zwave_event)}"
    )

    {:ok, []}
  end

  @type status :: :enabled | :disabled
  def status_to_byte(:disabled), do: 0x00
  def status_to_byte(:enabled), do: 0xFF

  def status_from_byte(0x00), do: {:ok, :disabled}
  def status_from_byte(0xFF), do: {:ok, :enabled}
  def status_from_byte(_byte), do: {:error, :invalid_status_byte}

  @spec encode_alarm_types([atom]) :: binary
  def encode_alarm_types(alarm_types) do
    for bit_list <- byte_indices(alarm_types, @alarm_types) do
      for bit <- Enum.reverse(bit_list), into: <<>>, do: <<bit::1>>
    end
    |> :binary.list_to_bin()
  end

  @spec encode_type_events(atom, [atom]) :: binary
  def encode_type_events(type, events) do
    reference = Keyword.fetch!(@type_events, type)

    for bit_list <- byte_indices(events, reference) do
      for bit <- Enum.reverse(bit_list), into: <<>>, do: <<bit::1>>
    end
    |> :binary.list_to_bin()
  end

  defp byte_indices(list_of_lists, reference) do
    for byte <- (Enum.count(reference) - 1)..0 do
      items_per_byte = Enum.at(reference, byte)

      for index <- 0..7 do
        if Enum.at(items_per_byte, index) in list_of_lists, do: 1, else: 0
      end
    end
    |> Enum.drop_while(fn indices -> Enum.all?(indices, &(&1 == 0)) end)
    |> Enum.reverse()
  end

  @spec decode_alarm_types(binary) :: {:ok, [atom()]} | {:error, :invalid_type}
  def decode_alarm_types(binary) do
    alarm_types =
      :binary.bin_to_list(binary)
      |> Enum.map(&bit_set_indices(<<&1>>))
      |> Enum.with_index()
      |> Enum.map(fn {bit_indices, byte} ->
        Enum.map(bit_indices, &decode_bit(byte, &1, @alarm_types))
      end)
      |> List.flatten()

    if Enum.any?(alarm_types, &(&1 == nil)) do
      {:error, :invalid_type}
    else
      {:ok, alarm_types}
    end
  end

  @spec decode_type_events(atom, binary) ::
          {:error, :invalid_type} | {:error, :invalid_type_event} | {:ok, [atom()]}
  def decode_type_events(type, binary) do
    with {:ok, reference} <- Keyword.fetch(@type_events, type) do
      type_events =
        :binary.bin_to_list(binary)
        |> Enum.map(&bit_set_indices(<<&1>>))
        |> Enum.with_index()
        |> Enum.map(fn {bit_indices, byte} ->
          Enum.map(bit_indices, &decode_bit(byte, &1, reference))
        end)
        |> List.flatten()

      if Enum.any?(type_events, &(&1 == nil)) do
        {:error, :invalid_type_event}
      else
        {:ok, type_events}
      end
    else
      :error ->
        {:error, :invalid_type_byte}
    end
  end

  defp bit_set_indices(byte) do
    for(<<x::1 <- byte>>, do: x)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce([], fn {bit, index}, acc ->
      if bit == 1, do: [index | acc], else: acc
    end)
  end

  defp decode_bit(byte, bit_index, reference) do
    Enum.at(reference, byte) |> Enum.at(bit_index)
  end
end
