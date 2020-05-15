defmodule Grizzly.ZWave.DeviceClasses do
  @moduledoc """
  Z-Wave device classes
  """

  defmodule Generate do
    @moduledoc false

    @basic_mappings [
      {0x01, :controller},
      {0x02, :static_controller},
      {0x03, :slave},
      {0x04, :routing_slave}
    ]

    @generic_mappings [
      {0x01, :generic_controller},
      {0x02, :static_controller},
      {0x03, :av_control_point},
      {0x04, :display},
      {0x05, :network_extender},
      {0x06, :appliance},
      {0x07, :sensor_notification},
      {0x08, :thermostat},
      {0x09, :window_covering},
      {0x0F, :repeater_slave},
      {0x10, :switch_binary},
      {0x11, :switch_multilevel},
      {0x12, :switch_remote},
      {0x13, :switch_toggle},
      {0x15, :zip_node},
      {0x16, :ventilation},
      {0x17, :security_panel},
      {0x18, :wall_controller},
      {0x20, :sensor_binary},
      {0x21, :sensor_multilevel},
      {0x30, :meter_pulse},
      {0x31, :meter},
      {0x40, :entry_control},
      {0x50, :semi_interoperable},
      {0xA1, :sensor_alarm},
      {0xFF, :non_interoperable}
    ]

    @specific_mappings [
      # generic controller (0x01)
      {:generic_controller, 0x00, :not_used},
      {:generic_controller, 0x01, :portable_remote_controller},
      {:generic_controller, 0x02, :portable_scene_controller},
      {:generic_controller, 0x03, :installer_tool},
      {:generic_controller, 0x04, :remote_control_av},
      {:generic_controller, 0x06, :remote_control_simple},
      # static controller (0x02)
      {:static_controller, 0x00, :not_used},
      {:static_controller, 0x01, :pc_controller},
      {:static_controller, 0x02, :scene_controller},
      {:static_controller, 0x03, :static_installer_tool},
      {:static_controller, 0x04, :set_top_box},
      {:static_controller, 0x05, :sub_system_controller},
      {:static_controller, 0x06, :tv},
      {:static_controller, 0x07, :gateway},
      # av control point (0x03)
      {:av_control_point, 0x00, :not_used},
      {:av_control_point, 0x04, :satellite_receiver},
      {:av_control_point, 0x11, :satellite_receiver_v2},
      {:av_control_point, 0x12, :doorbell},
      # display
      {:display, 0x00, :not_used},
      {:display, 0x01, :simple_display},
      # network_extender
      {:network_extender, 0x00, :not_used},
      {:network_extender, 0x01, :secure_extender},
      # appliance
      {:appliance, 0x00, :not_used},
      {:appliance, 0x01, :general_appliance},
      {:appliance, 0x02, :kitchen_appliance},
      {:appliance, 0x03, :laundry_appliance},
      # sensor_notification
      {:sensor_notification, 0x00, :not_used},
      {:sensor_notification, 0x01, :notification_sensor},
      # thermostat
      {:thermostat, 0x00, :not_used},
      {:thermostat, 0x01, :thermostat_heating},
      {:thermostat, 0x02, :thermostat_general},
      {:thermostat, 0x03, :setback_schedule_thermostat},
      {:thermostat, 0x04, :setpoint_thermostat},
      {:thermostat, 0x05, :setback_thermostat},
      {:thermostat, 0x06, :thermostat_general_v2},
      # window covering
      {:window_covering, 0x00, :not_used},
      {:window_covering, 0x01, :simple_window_covering},
      # switch_binary
      {:switch_binary, 0x00, :not_used},
      {:switch_binary, 0x01, :power_switch_binary},
      {:switch_binary, 0x02, :color_tunable_binary},
      {:switch_binary, 0x03, :scene_switch_binary},
      {:switch_binary, 0x04, :power_strip},
      {:switch_binary, 0x05, :siren},
      {:switch_binary, 0x06, :valve_open_close},
      {:switch_binary, 0x07, :irrigation_controller},
      # switch multilevel
      {:switch_multilevel, 0x00, :not_used},
      {:switch_multilevel, 0x01, :power_switch_multilevel},
      {:switch_multilevel, 0x02, :color_tunable_multilevel},
      {:switch_multilevel, 0x03, :motor_multipositions},
      {:switch_multilevel, 0x04, :scene_switch_multilevel},
      {:switch_multilevel, 0x05, :class_a_motor_control},
      {:switch_multilevel, 0x06, :class_b_motor_control},
      {:switch_multilevel, 0x07, :class_c_motor_control},
      {:switch_multilevel, 0x08, :fan_switch},
      # switch remote (0x13)
      {:switch_remote, 0x00, :not_used},
      {:switch_remote, 0x01, :switch_remote_binary},
      {:switch_remote, 0x02, :switch_remote_multilevel},
      {:switch_remote, 0x03, :switch_remote_toggle_binary},
      {:switch_remote, 0x04, :switch_remote_toggle_multilevel},
      # switch toggle (0x14)
      {:switch_toggle, 0x00, :not_used},
      {:switch_toggle, 0x01, :switch_toggle_binary},
      {:switch_toggle, 0x02, :switch_toggle_multilevel},
      # zip node (0x15)
      {:zip_node, 0x00, :not_used},
      {:zip_node, 0x01, :zip_adv_node},
      {:zip_node, 0x02, :zip_tun_node},
      # security_panel (0x17)
      {:security_panel, 0x00, :not_used},
      {:security_panel, 0x01, :zoned_security_panel},
      # wall controller (0x18)
      {:wall_controller, 0x00, :not_used},
      {:wall_controller, 0x01, :basic_wall_controller},
      # sensor binary (0x20)
      {:sensor_binary, 0x00, :not_used},
      {:sensor_binary, 0x01, :routing_sensor_binary},
      # sensor multilevel (0x21)
      {:sensor_multilevel, 0x00, :not_used},
      {:sensor_multilevel, 0x01, :routing_sensor_multilevel},
      {:sensor_multilevel, 0x02, :chimney_fan},
      # meter pulse (0x30)
      {:meter_pulse, 0x00, :not_used},
      # meter (0x31)
      {:meter, 0x00, :not_used},
      {:meter, 0x01, :simple_meter},
      {:meter, 0x02, :adv_energy_meter},
      {:meter, 0x03, :whole_home_meter_simple},
      # entry control (0x40)
      {:entry_control, 0x00, :not_used},
      {:entry_control, 0x01, :door_lock},
      {:entry_control, 0x02, :advanced_door_lock},
      {:entry_control, 0x03, :secure_keypad_door_lock},
      {:entry_control, 0x04, :secure_keypad_door_lock_deadbolt},
      {:entry_control, 0x05, :secure_door},
      {:entry_control, 0x06, :secure_gate},
      {:entry_control, 0x07, :secure_barrier_addon},
      {:entry_control, 0x08, :secure_barrier_open_only},
      {:entry_control, 0x09, :secure_barrier_close_only},
      {:entry_control, 0x0A, :secure_lockbox},
      {:entry_control, 0x0B, :secure_keypad},
      # semi interoperable (0x50)
      {:semi_interoperable, 0x00, :not_used},
      {:semi_interoperable, 0x01, :energy_production},
      # sensor alarm (0xA1)
      {:sensor_alarm, 0x00, :not_used},
      {:sensor_alarm, 0x01, :basic_routing_alarm_sensor},
      {:sensor_alarm, 0x02, :routing_alarm_sensor},
      {:sensor_alarm, 0x03, :basic_zensor_net_alarm_sensor},
      {:sensor_alarm, 0x04, :zensor_net_alarm_sensor},
      {:sensor_alarm, 0x05, :adv_zensor_net_alarm_sensor},
      {:sensor_alarm, 0x06, :basic_routing_smoke_sensor},
      {:sensor_alarm, 0x07, :routing_smoke_sensor},
      {:sensor_alarm, 0x08, :basic_zensor_net_smoke_sensor},
      {:sensor_alarm, 0x09, :zensor_net_smoke_sensor},
      {:sensor_alarm, 0x0A, :adv_zensor_net_smoke_sensor},
      {:sensor_alarm, 0x0B, :alarm_sensor},
      # non interoperable (0xFF)
      {:non_interoperable, 0x00, :not_used}
    ]

    defmacro __before_compile__(_) do
      basic_device_class_from_byte =
        for {byte, device_class} <- @basic_mappings do
          quote do
            def basic_device_class_from_byte(unquote(byte)), do: {:ok, unquote(device_class)}
          end
        end

      basic_device_class_to_byte =
        for {byte, device_class} <- @basic_mappings do
          quote do
            def basic_device_class_to_byte(unquote(device_class)), do: unquote(byte)
          end
        end

      generic_device_class_from_byte =
        for {byte, device_class} <- @generic_mappings do
          quote do
            def generic_device_class_from_byte(unquote(byte)), do: {:ok, unquote(device_class)}
          end
        end

      generic_device_class_to_byte =
        for {byte, device_class} <- @generic_mappings do
          quote do
            def generic_device_class_to_byte(unquote(device_class)), do: unquote(byte)
          end
        end

      specific_device_class_from_byte =
        for {gen_class, byte, spec_class} <- @specific_mappings do
          quote do
            def specific_device_class_from_byte(unquote(gen_class), unquote(byte)),
              do: {:ok, unquote(spec_class)}
          end
        end

      specific_device_class_to_byte =
        for {gen_class, byte, spec_class} <- @specific_mappings do
          quote do
            def specific_device_class_to_byte(unquote(gen_class), unquote(spec_class)),
              do: unquote(byte)
          end
        end

      quote do
        @type basic_device_class :: :controller | :static_controller | :slave | :routing_slave

        @type generic_device_class ::
                :generic_controller
                | :static_controller
                | :av_control_point
                | :display
                | :network_extender
                | :appliance
                | :sensor_notification
                | :thermostat
                | :window_covering
                | :repeater_slave
                | :switch_binary
                | :switch_multilevel
                | :switch_remote
                | :switch_toggle
                | :zip_node
                | :ventilation
                | :security_panel
                | :wall_controller
                | :sensor_binary
                | :sensor_multilevel
                | :meter_pulse
                | :meter
                | :entry_control
                | :semi_interoperable
                | :sensor_alarm
                | :non_interoperable

        @type specific_device_class ::
                :not_used
                | :portable_remote_controller
                | :portable_scene_controller
                | :installer_tool
                | :remote_control_av
                | :remote_control_simple
                | :pc_controller
                | :scene_controller
                | :static_installer_tool
                | :set_top_box
                | :sub_system_controller
                | :tv
                | :gateway
                | :satellite_receiver
                | :satellite_receiver_v2
                | :doorbell
                | :simple_display
                | :secure_extender
                | :general_appliance
                | :kitchen_appliance
                | :laundry_appliance
                | :notification_sensor
                | :thermostat_heating
                | :thermostat_general
                | :setback_schedule_thermostat
                | :setpoint_thermostat
                | :setback_thermostat
                | :thermostat_general_v2
                | :simple_window_covering
                | :power_switch_binary
                | :color_tunable_binary
                | :scene_switch_binary
                | :power_strip
                | :siren
                | :valve_open_close
                | :irrigation_controller
                | :power_switch_multilevel
                | :color_tunable_multilevel
                | :motor_multipositions
                | :scene_switch_multilevel
                | :class_a_motor_control
                | :class_b_motor_control
                | :class_c_motor_control
                | :fan_switch
                | :switch_remote_binary
                | :switch_remote_multilevel
                | :switch_remote_toggle_binary
                | :switch_remote_toggle_multilevel
                | :switch_toggle_binary
                | :switch_toggle_multilevel
                | :zip_adv_node
                | :zip_tun_node
                | :zoned_security_panel
                | :basic_wall_controller
                | :routing_sensor_binary
                | :routing_sensor_multilevel
                | :chimney_fan
                | :simple_meter
                | :adv_energy_meter
                | :whole_home_meter_simple
                | :door_lock
                | :advanced_door_lock
                | :secure_door_lock
                | :secure_keypad_door_lock
                | :secure_keypad_door_lock_deadbolt
                | :secure_door
                | :secure_gate
                | :secure_barrier_addon
                | :secure_barrier_open_only
                | :secure_barrier_close_only
                | :secure_lockbox
                | :energy_production
                | :basic_routing_alarm_sensor
                | :routing_alarm_sensor
                | :basic_zensor_net_alarm_sensor
                | :zensor_net_alarm_sensor
                | :adv_zensor_net_alarm_sensor
                | :basic_routing_smoke_sensor
                | :routing_smoke_sensor
                | :basic_zensor_net_smoke_sensor
                | :zensor_net_smoke_sensor
                | :adv_zensor_net_smoke_sensor
                | :alarm_sensor
                | :portable_scene_controller

        @doc """
        Try to make a basic device class from a byte
        """
        @spec basic_device_class_from_byte(byte()) ::
                {:ok, basic_device_class()} | {:error, :unsupported_device_class}
        unquote(basic_device_class_from_byte)
        def basic_device_class_from_byte(_byte), do: {:error, :unsupported_device_class}

        @doc """
        Make a byte from a device class
        """
        @spec basic_device_class_to_byte(basic_device_class()) :: byte()
        unquote(basic_device_class_to_byte)

        @doc """
        Try to get the generic device class for the byte
        """
        @spec generic_device_class_from_byte(byte()) ::
                {:ok, generic_device_class()} | {:error, :unsupported_device_class}
        unquote(generic_device_class_from_byte)
        def generic_device_class_from_byte(_byte), do: {:error, :unsupported_device_class}

        @doc """
        Turn the generic device class into a byte
        """
        @spec generic_device_class_to_byte(generic_device_class()) :: byte()
        unquote(generic_device_class_to_byte)

        @doc """
        Try to get the specific device class from the byte given the generic device class
        """
        @spec specific_device_class_from_byte(generic_device_class(), byte()) ::
                {:ok, specific_device_class()} | {:error, :unsupported_device_class}
        unquote(specific_device_class_from_byte)
        def specific_device_class_from_byte(_, _byte), do: {:error, :unsupported_device_class}

        @doc """
        Make the specific device class into a byte
        """
        @spec specific_device_class_to_byte(generic_device_class(), specific_device_class()) ::
                byte()
        unquote(specific_device_class_to_byte)
      end
    end
  end

  @before_compile Generate
end
