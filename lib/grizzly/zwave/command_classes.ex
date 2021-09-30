defmodule Grizzly.ZWave.CommandClasses do
  require Logger

  defmodule Generate do
    @moduledoc false

    @mappings [
      {0x00, :no_operation},
      {0x02, :zensor_net},
      {0x20, :basic},
      {0x21, :controller_replication},
      {0x22, :application_status},
      {0x23, :zip},
      {0x24, :security_panel_mode},
      {0x25, :switch_binary},
      {0x26, :switch_multilevel},
      {0x27, :switch_all},
      {0x28, :switch_toggle_binary},
      {0x2A, :chimney_fan},
      {0x2B, :scene_activation},
      {0x2C, :scene_actuator_conf},
      {0x2D, :scene_controller_conf},
      {0x2E, :security_panel_zone},
      {0x2F, :security_panel_zone_sensor},
      {0x30, :sensor_binary},
      {0x31, :sensor_multilevel},
      {0x32, :meter},
      {0x33, :switch_color},
      {0x34, :network_management_inclusion},
      {0x35, :meter_pulse},
      {0x36, :basic_tariff_info},
      {0x37, :hrv_status},
      {0x38, :thermostat_heating},
      {0x39, :hrv_control},
      {0x3A, :dcp_config},
      {0x3B, :dcp_monitor},
      {0x3C, :meter_tbl_config},
      {0x3D, :meter_tbl_monitor},
      {0x3E, :meter_tbl_push},
      {0x3F, :prepayment},
      {0x40, :thermostat_mode},
      {0x41, :prepayment_encapsulation},
      {0x42, :thermostat_operating_state},
      {0x43, :thermostat_setpoint},
      {0x44, :thermostat_fan_mode},
      {0x45, :thermostat_fan_state},
      {0x46, :climate_control_schedule},
      {0x47, :thermostat_setback},
      {0x48, :rate_tbl_config},
      {0x49, :rate_tbl_monitor},
      {0x4A, :tariff_config},
      {0x4B, :tariff_tbl_monitor},
      {0x4C, :door_lock_logging},
      {0x4D, :network_management_basic},
      {0x4E, :schedule_entry_lock},
      {0x4F, :zip_6lowpan},
      {0x50, :basic_window_covering},
      {0x51, :mtp_window_covering},
      {0x52, :network_management_proxy},
      {0x53, :schedule},
      {0x54, :network_management_primary},
      {0x55, :transport_service},
      {0x56, :crc_16_encap},
      {0x57, :application_capability},
      {0x58, :zip_nd},
      {0x59, :association_group_info},
      {0x5A, :device_reset_locally},
      {0x5B, :central_scene},
      {0x5C, :ip_association},
      {0x5D, :antitheft},
      {0x5E, :zwaveplus_info},
      {0x5F, :zip_gateway},
      {0x60, :multi_channel},
      {0x61, :zip_portal},
      {0x62, :door_lock},
      {0x63, :user_code},
      {0x64, :humidity_control_setpoint},
      {0x65, :dmx},
      {0x66, :barrier_operator},
      {0x67, :network_management_installation_maintenance},
      {0x68, :zip_naming},
      {0x69, :mailbox},
      {0x6A, :window_covering},
      {0x6B, :irrigation},
      {0x6C, :supervision},
      {0x6D, :humidity_control_mode},
      {0x6E, :humidity_control_operating_state},
      {0x6F, :entry_control},
      {0x70, :configuration},
      {0x71, :alarm},
      {0x72, :manufacturer_specific},
      {0x73, :powerlevel},
      {0x74, :inclusion_controller},
      {0x75, :protection},
      {0x76, :lock},
      {0x77, :node_naming},
      {0x78, :node_provisioning},
      {0x7A, :firmware_update_md},
      {0x7B, :grouping_name},
      {0x7C, :remote_association_activate},
      {0x7D, :remote_association},
      {0x7E, :antitheft_unlock},
      {0x80, :battery},
      {0x81, :clock},
      {0x82, :hail},
      {0x84, :wake_up},
      {0x85, :association},
      {0x86, :version},
      {0x87, :indicator},
      {0x88, :proprietary},
      {0x89, :language},
      {0x8A, :time},
      {0x8B, :time_parameters},
      {0x8C, :geographic_location},
      {0x8E, :multi_channel_association},
      {0x8F, :multi_cmd},
      {0x90, :energy_production},
      {0x91, :manufacturer_proprietary},
      {0x92, :screen_md},
      {0x93, :screen_attributes},
      {0x94, :simple_av_control},
      {0x95, :av_content_directory_md},
      {0x96, :av_content_renderer_status},
      {0x97, :av_content_search_md},
      {0x98, :security},
      {0x99, :av_tagging_md},
      {0x9A, :ip_configuration},
      {0x9B, :association_command_configuration},
      {0x9C, :sensor_alarm},
      {0x9D, :silence_alarm},
      {0x9E, :sensor_configuration},
      {0x9F, :security_2},
      {0xEF, :mark},
      {0xF0, :non_interoperable}
    ]

    defmacro __before_compile__(_) do
      to_byte =
        for {byte, command_class} <- @mappings do
          quote do
            def to_byte(unquote(command_class)), do: unquote(byte)
          end
        end

      from_byte =
        for {byte, command_class} <- @mappings do
          quote do
            def from_byte(unquote(byte)), do: {:ok, unquote(command_class)}
          end
        end

      quote do
        @type command_class ::
                :zensor_net
                | :basic
                | :controller_replication
                | :application_status
                | :zip
                | :security_panel_mode
                | :switch_binary
                | :switch_multilevel
                | :switch_all
                | :switch_toggle_binary
                | :chimney_fan
                | :scene_activation
                | :scene_actuator_conf
                | :scene_controller_conf
                | :security_panel_zone
                | :security_panel_zone_sensor
                | :sensor_binary
                | :sensor_multilevel
                | :meter
                | :switch_color
                | :network_management_inclusion
                | :meter_pulse
                | :basic_tariff_info
                | :hrv_status
                | :thermostat_heating
                | :hrv_control
                | :dcp_config
                | :dcp_monitor
                | :meter_tbl_config
                | :meter_tbl_monitor
                | :meter_tbl_push
                | :prepayment
                | :thermostat_mode
                | :prepayment_encapsulation
                | :operating_state
                | :thermostat_setpoint
                | :thermostat_fan_mode
                | :thermostat_fan_state
                | :climate_control_schedule
                | :thermostat_setback
                | :rate_tbl_config
                | :rate_tbl_monitor
                | :tariff_config
                | :tariff_tbl_monitor
                | :door_lock_logging
                | :network_management_basic
                | :schedule_entry_lock
                | :zip_6lowpan
                | :basic_window_covering
                | :mtp_window_covering
                | :network_management_proxy
                | :schedule
                | :network_management_primary
                | :transport_service
                | :crc_16_encap
                | :application_capability
                | :zip_nd
                | :association_group_info
                | :device_reset_locally
                | :central_scene
                | :ip_association
                | :antitheft
                | :zwaveplus_info
                | :zip_gateway
                | :zip_portal
                | :door_lock
                | :user_code
                | :humidity_control_setpoint
                | :dmx
                | :barrier_operator
                | :network_management_installation_maintenance
                | :zip_naming
                | :mailbox
                | :window_covering
                | :irrigation
                | :supervision
                | :humidity_control_mode
                | :humidity_control_operating_state
                | :entry_control
                | :configuration
                | :alarm
                | :manufacturer_specific
                | :powerlevel
                | :inclusion_controller
                | :protection
                | :lock
                | :node_naming
                | :node_provisioning
                | :firmware_update_md
                | :grouping_name
                | :remote_association_activate
                | :remote_association
                | :battery
                | :clock
                | :hail
                | :wake_up
                | :association
                | :version
                | :indicator
                | :proprietary
                | :language
                | :time
                | :time_parameters
                | :geographic_location
                | :multi_channel
                | :multi_channel_association
                | :multi_cmd
                | :energy_production
                | :manufacturer_proprietary
                | :screen_md
                | :screen_attributes
                | :simple_av_control
                | :av_content_directory_md
                | :av_content_renderer_status
                | :av_content_search_md
                | :security
                | :av_tagging_md
                | :ip_configuration
                | :association_command_configuration
                | :sensor_alarm
                | :silence_alarm
                | :sensor_configuration
                | :security_2
                | :mark
                | :non_interoperable
                | :no_operation

        @doc """
        Try to parse the byte into a command class
        """
        @spec from_byte(byte()) :: {:ok, command_class()} | {:error, :unsupported_command_class}
        unquote(from_byte)

        def from_byte(byte) do
          Logger.warn("[Grizzly] Unsupported command class from byte #{byte}")
          {:error, :unsupported_command_class}
        end

        @doc """
        Get the byte representation of the command class
        """
        @spec to_byte(command_class()) :: byte()
        unquote(to_byte)
      end
    end
  end

  @before_compile Generate

  @doc """
  Turn the list of command classes into the binary representation outlined in
  the Network-Protocol command class specification.

  TODO: add more details
  """
  @spec command_class_list_to_binary([command_class()]) :: binary()
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
  @spec command_class_list_from_binary(binary()) :: [command_class()]
  def command_class_list_from_binary(binary) do
    binary_list = :erlang.binary_to_list(binary)

    {_, command_classes} =
      Enum.reduce(
        binary_list,
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

          0xF1, {_, command_classes} ->
            {:secure_supported, command_classes}

          0x00, {_, command_classes} ->
            {:secure_supported, command_classes}

          0xEF, {:secure_supported, command_classes} ->
            {:secure_controlled, command_classes}

          command_class_byte, {security, command_classes}
          when command_class_byte not in [0xF1, 0xEF, 0x00] ->
            # Right now lets fail super hard so we can add support for
            # new command classes quickly
            {:ok, command_class} = from_byte(command_class_byte)
            {security, Keyword.update(command_classes, security, [], &(&1 ++ [command_class]))}
        end
      )

    command_classes
  end

  def maybe_concat_command_classes(binary, _, <<>>), do: binary

  def maybe_concat_command_classes(binary, :non_secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>

  def maybe_concat_command_classes(binary, :secure_supported, ccs_bin),
    do: binary <> <<0xF1, 0x00, ccs_bin::binary>>

  def maybe_concat_command_classes(binary, :secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>
end
