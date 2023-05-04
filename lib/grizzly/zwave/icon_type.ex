defmodule Grizzly.ZWave.IconType do
  @moduledoc """
  The installer icon type is used in Z-Wave Plus devices to allow
  interoperability with generic Z-Wave graphical user interfaces.

  These interfaces are useful when using generic Z-Wave tooling
  and debugging to allow the user to get a meaningful representation
  of any product included in the network, and is mandatory according
  the Z-Wave Plus specification.

  See `SDS11847 Z-Wave Plus Device Type Specification.pdf` Appendix A
  provided by Silicon Labs for more information.
  """

  defmodule Generate do
    @moduledoc false

    @mappings [
      {0x0000, :unassigned},
      {0x0100, :generic_central_controller},
      {0x0200, :generic_display_simple},
      {0x0300, :generic_door_lock_keypad},
      {0x0400, :generic_fan_switch_device_type},
      {0x0500, :gateway},
      {0x0600, :generic_light_dimmer_switch},
      {0x0601, :specific_light_dimmer_plugin},
      {0x0602, :specific_light_dimmer_switch_wall_outlet},
      {0x0603, :specific_light_dimmer_switch_ceiling_outlet},
      {0x0604, :specific_light_dimmer_switch_wall_lamp},
      {0x0605, :specific_light_dimmer_switch_lamp_post_high},
      {0x0606, :specific_light_dimmer_switch_lamp_post_low},
      {0x0607, :specific_light_dimmer_switch_din_rail_module},
      {0x0700, :generic_on_off_power_switch},
      {0x0701, :specific_on_off_power_switch_plugin},
      {0x0702, :specific_on_off_power_switch_wall_outlet},
      {0x0703, :specific_on_off_power_switch_ceiling_outlet},
      {0x0704, :specific_on_off_power_switch_wall_lamp},
      {0x0705, :specific_on_off_power_switch_lamp_post_high},
      {0x0706, :specific_on_off_power_switch_lamp_post_low},
      {0x0707, :specific_on_off_power_switch_din_rail_module},
      {0x0800, :generic_power_strip},
      {0x08FF, :specific_power_strip_individual_outlet},
      {0x0900, :generic_remote_control_av},
      {0x0A00, :generic_remote_control_multi_purpose},
      {0x0B00, :generic_remote_control_simple},
      {0x0B01, :specific_remote_control_simple_keyfob},
      {0x0C00, :generic_sensor_notification},
      {0x0C01, :specific_sensor_notification_smoke_alarm},
      {0x0C02, :specific_sensor_notification_co_alarm},
      {0x0C03, :specific_sensor_notification_co2_alarm},
      {0x0C04, :specific_sensor_notification_heat_alarm},
      {0x0C05, :specific_sensor_notification_water_alarm},
      {0x0C06, :specific_sensor_notification_door_window},
      {0x0C07, :specific_sensor_notification_motion_alarm},
      {0x0C08, :specific_sensor_notification_power_management},
      {0x0C09, :specific_sensor_notification_system},
      {0x0C0A, :specific_sensor_notification_emergency_alarm},
      {0x0C0B, :specific_sensor_notification_clock},
      {0x0C0C, :specific_sensor_notification_appliance},
      {0x0C0D, :specific_sensor_notification_home_health},
      {0x0C0E, :specific_sensor_notification_siren},
      {0x0C0F, :specific_sensor_notification_water_valve},
      {0x0C10, :specific_sensor_notification_weather_alarm},
      {0x0C11, :specific_sensor_notification_irrigation},
      {0x0C12, :specific_sensor_notification_gas_alarm},
      {0x0C13, :specific_sensor_notification_pest_control},
      {0x0C14, :specific_sensor_notification_light_sensor},
      {0x0CFF, :specific_sensor_notification_multidevice},
      {0x0D00, :generic_sensor_multilevel},
      {0x0D01, :specific_sensor_multilevel_air_temperature},
      {0x0D02, :specific_sensor_multilevel_general_purpose_value},
      {0x0D03, :specific_sensor_multilevel_luminance},
      {0x0D04, :specific_sensor_multilevel_power},
      {0x0D05, :specific_sensor_multilevel_humidity},
      {0x0D06, :specific_sensor_multilevel_velocity},
      {0x0D07, :specific_sensor_multilevel_direction},
      {0x0D08, :specific_sensor_multilevel_atmospheric_pressure},
      {0x0D09, :specific_sensor_multilevel_barometric_pressure},
      {0x0D0A, :specific_sensor_multilevel_solor_radiation},
      {0x0D0B, :specific_sensor_multilevel_dew_point},
      {0x0D0C, :specific_sensor_multilevel_rain_rate},
      {0x0D0D, :specific_sensor_multilevel_tide_level},
      {0x0D0E, :specific_sensor_multilevel_weight},
      {0x0D0F, :specific_sensor_multilevel_voltage},
      {0x0D10, :specific_sensor_multilevel_current},
      {0x0D11, :specific_sensor_multilevel_co2_level},
      {0x0D12, :specific_sensor_multilevel_air_flow},
      {0x0D13, :specific_sensor_multilevel_tank_capacity},
      {0x0D14, :specific_sensor_multilevel_distance},
      {0x0D15, :specific_sensor_multilevel_angle_position},
      {0x0D16, :specific_sensor_multilevel_rotation},
      {0x0D17, :specific_sensor_multilevel_water_temperature},
      {0x0D18, :specific_sensor_multilevel_soil_temperature},
      {0x0D19, :specific_sensor_multilevel_seismic_intensity},
      {0x0D1A, :specific_sensor_multilevel_seismic_magnitude},
      {0x0D1B, :specific_sensor_multilevel_ultraviolet},
      {0x0D1C, :specific_sensor_multilevel_electrical_resistivity},
      {0x0D1D, :specific_sensor_multilevel_electrical_conductivity},
      {0x0D1E, :specific_sensor_multilevel_loudness},
      {0x0D1F, :specific_sensor_multilevel_moisture},
      {0x0D20, :specific_sensor_multilevel_frequency},
      {0x0D21, :specific_sensor_multilevel_time},
      {0x0D22, :specific_sensor_multilevel_target_temperature},
      {0x0D23, :specific_sensor_multilevel_particulate_matter_2_5},
      {0x0D24, :specific_sensor_multilevel_formaldehyde_ch2o_level},
      {0x0D25, :specific_sensor_multilevel_radon_concentration},
      {0x0D26, :specific_sensor_multilevel_methane_density},
      {0x0D27, :specific_sensor_multilevel_volatile_organic_compound_level},
      {0x0D28, :specific_sensor_multilevel_carbon_monoxide_level},
      {0x0D29, :specific_sensor_multilevel_soil_humidity},
      {0x0D2A, :specific_sensor_multilevel_soil_reactivity},
      {0x0D2B, :specific_sensor_multilevel_soil_salinity},
      {0x0D2C, :specific_sensor_multilevel_heart_rate},
      {0x0D2D, :specific_sensor_multilevel_blood_pressure},
      {0x0D2E, :specific_sensor_multilevel_muscle_mass},
      {0x0D2F, :specific_sensor_multilevel_fat_mass},
      {0x0D30, :specific_sensor_multilevel_bone_mass},
      {0x0D31, :specific_sensor_multilevel_total_body_water},
      {0x0D32, :specific_sensor_multilevel_basis_metabolic_rate},
      {0x0D33, :specific_sensor_multilevel_body_mass_index},
      {0x0D34, :specific_sensor_multilevel_acceleration_x_axis},
      {0x0D35, :specific_sensor_multilevel_acceleration_y_axis},
      {0x0D36, :specific_sensor_multilevel_acceleration_z_axis},
      {0x0D37, :specific_sensor_multilevel_smoke_density},
      {0x0D38, :specific_sensor_multilevel_water_flow},
      {0x0D39, :specific_sensor_multilevel_water_density},
      {0x0D3A, :specific_sensor_multilevel_rf_signal_strength},
      {0x0D3B, :specific_sensor_multilevel_particulate_matter_10},
      {0x0D3C, :specific_sensor_multilevel_respiratory_rate},
      {0x0D3D, :specific_sensor_multilevel_relative_modulation_level},
      {0x0D3E, :specific_sensor_multilevel_boiler_water_temperature},
      {0x0D3F, :specific_sensor_multilevel_domestic_hot_water_temperature},
      {0x0D40, :specific_sensor_multilevel_outside_temperature},
      {0x0D41, :specific_sensor_multilevel_exhaust_temperature},
      {0x0D42, :specific_sensor_multilevel_water_chlorine_level},
      {0x0D43, :specific_sensor_multilevel_water_acidity},
      {0x0D44, :specific_sensor_multilevel_water_oxidation_reduction_potential},
      {0x0DFF, :specific_sensor_multilevel_multidevice},
      {0x0E00, :generic_set_top_box},
      {0x0F00, :generic_siren},
      {0x1000, :generic_sub_energy_meter},
      {0x1100, :generic_sub_system_controller},
      {0x1200, :generic_thermostat},
      {0x1201, :specific_thermostat_line_voltage},
      {0x1202, :specific_thermostat_setback},
      {0x1300, :generic_thermostat_setback_obsoleted},
      {0x1400, :generic_tv},
      {0x1500, :generic_valve_open_close},
      {0x1600, :generic_wall_controller},
      {0x1700, :generic_whole_home_meter_simple},
      {0x1800, :generic_window_covering_no_position_endpoint},
      {0x1900, :generic_window_covering_endpoint_aware},
      {0x1A00, :generic_window_covering_position_endpoint_aware},
      {0x1B00, :generic_repeater},
      {0x1B01, :specific_repeater_end_node},
      {0x1B03, :specific_ir_repeater},
      {0x1C00, :generic_dimmer_wall_switch},
      {0x1C01, :specific_dimmer_wall_switch_one_button},
      {0x1C02, :specific_dimmer_wall_switch_two_buttons},
      {0x1C03, :specific_dimmer_wall_switch_three_buttons},
      {0x1C04, :specific_dimmer_wall_switch_four_buttons},
      {0x1CF1, :specific_dimmer_wall_switch_one_rotary},
      {0x1D00, :generic_on_off_wall_switch},
      {0x1D01, :specific_on_off_wall_switch_one_button},
      {0x1D02, :specific_on_off_wall_switch_two_buttons},
      {0x1D03, :specific_on_off_wall_switch_three_buttons},
      {0x1D04, :specific_on_off_wall_switch_four_buttons},
      {0x1DE1, :specific_on_off_wall_switch_door_bell},
      {0x1DF1, :specific_on_off_wall_switch_one_rotary},
      {0x1E00, :generic_barrier},
      {0x1F00, :generic_irrigation},
      {0x2000, :generic_entry_control},
      {0x2001, :specific_entry_control_keypad_0_9},
      {0x2002, :specific_entry_control_rfid_tag_reader_no_button},
      {0x2003, :specific_entry_control_keypad_0_9_ok_cancel},
      {0x2004, :specific_entry_control_keypad_0_9_ok_cancel_home_stay_away},
      {0x2100, :generic_sensor_notification_home_security},
      {0x2101, :specific_sensor_notification_home_security_intrusion},
      {0x2102, :specific_sensor_notification_home_security_glass_breakage},
      {0x2200, :generic_sound_switch},
      {0x2201, :specific_sound_switch_doorbell},
      {0x2202, :specific_sound_switch_chime},
      {0x2203, :specific_sound_switch_alarm_clock}
    ]

    defmacro __before_compile__(_) do
      to_name =
        for {integer, name} <- @mappings do
          quote do
            def to_name(unquote(integer)), do: {:ok, unquote(name)}
          end
        end

      to_value =
        for {integer, name} <- @mappings do
          quote do
            def to_value(unquote(name)), do: {:ok, unquote(integer)}
          end
        end

      quote do
        @type name :: atom()

        @type value :: 0x0000..0x2203

        @doc """
        Get the icon type's name from a 16-bit integer value
        """
        @spec to_name(value()) :: {:ok, name()} | {:error, :unknown_icon_type}
        unquote(to_name)
        def to_name(_), do: {:error, :unknown_icon_type}

        @doc """
        Get the 16-bit integer value from the icon type's name
        """
        @spec to_value(name()) :: {:ok, value()} | {:error, :unknown_icon_type}
        unquote(to_value)
        def to_value(_), do: {:error, :unknown_icon_type}
      end
    end
  end

  @before_compile Generate
end
