defmodule Grizzly.ZWave.DeviceClasses do
  @moduledoc """
  Z-Wave device classes
  """

  defmodule Generate do
    @moduledoc false

    @basic_mappings [
      {0x01, :controller},
      {0x02, :static_controller},
      {0x03, :end_node},
      {0x04, :routing_end_node}
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
      {0x0F, :repeater_end_node},
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
      {:av_control_point, 0x01, :sound_switch},
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
      # repeater end_node
      {:repeater_end_node, 0x00, :not_used},
      {:repeater_end_node, 0x01, :repeater_end_node},
      {:repeater_end_node, 0x02, :virtual_node},
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

      basic_classes_union =
        @basic_mappings
        |> Enum.map(&elem(&1, 1))
        |> Enum.reverse()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      generic_classes_union =
        @generic_mappings
        |> Enum.map(&elem(&1, 1))
        |> Enum.reverse()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      specific_classes_union =
        @specific_mappings
        |> Enum.map(&elem(&1, 2))
        |> Enum.reverse()
        |> Enum.uniq()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      quote do
        @type basic_device_class :: unquote(basic_classes_union)
        @type generic_device_class :: unquote(generic_classes_union)
        @type specific_device_class :: unquote(specific_classes_union)

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
