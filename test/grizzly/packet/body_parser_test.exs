defmodule Grizzly.Packet.BodyParser.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet.BodyParser

  alias Grizzly.CommandClass.{
    Configuration,
    NetworkManagementBasic,
    CommandClassVersion,
    FirmwareUpdateMD
  }

  describe "Parsing inclusion and exclusion" do
    test "include dimmer" do
      inclusion_ok = <<
        0x34,
        0x02,
        0x01,
        0x06,
        0x00,
        0x06,
        0x14,
        0xD3,
        0x9C,
        0x04,
        0x11,
        0x1,
        0x5E,
        0x86,
        0x72,
        0x5A,
        0x85,
        0x5C,
        0x59,
        0x73,
        0x26,
        0x27,
        0x70,
        0x7A,
        0x68,
        0x23,
        0x00,
        0x00,
        0x00
      >>

      parsed = BodyParser.parse(inclusion_ok)

      assert parsed == %{
               command_class: :network_management_inclusion,
               command: :node_add_status,
               seq_no: 0x01,
               status: :done,
               listening?: true,
               node_id: 0x06,
               basic_class: :routing_slave,
               generic_class: :switch_multilevel,
               specific_class: :power_switch_multilevel,
               command_classes: [
                 :zwaveplus_info,
                 :command_class_version,
                 :manufacturer_specific,
                 :device_rest_locally,
                 :association,
                 :ip_association,
                 :association_group_info,
                 :powerlevel,
                 :switch_multilevel,
                 :switch_all,
                 :configuration,
                 :firmware_update_md,
                 :zip_naming,
                 :zip
               ],
               secure: false,
               dsk: "",
               dsk_length: 0x00,
               keys_granted: [],
               kex_fail_type: :none
             }
    end

    test "exclusion did not work" do
      exclusion_fail = <<0x34, 0x04, 0x01, 0x07, 0x00>>
      parsed = BodyParser.parse(exclusion_fail)

      assert parsed == %{
               command_class: :network_management_inclusion,
               command: :node_remove_status,
               seq_no: 0x01,
               node_id: nil,
               status: :failed
             }
    end

    test "inclusion did not work" do
      inclusion_fail = <<0x34, 0x02, 0x01, 0x07, 0x00>>

      parsed = BodyParser.parse(inclusion_fail)

      assert parsed == %{
               command_class: :network_management_inclusion,
               command: :node_add_status,
               seq_no: 0x01,
               status: :failed
             }
    end

    test "include Yale YRD226 (Assure Lock)" do
      inclusion_ok = <<
        0x34,
        0x02,
        0x1C,
        0x06,
        0x00,
        0x1D,
        0x1E,
        0x53,
        0xDC,
        0x04,
        0x40,
        0x03,
        0x53,
        0x72,
        0x98,
        0x5A,
        0x73,
        0x86,
        0x68,
        0x23,
        0xF1,
        0x00,
        0x80,
        0x62,
        0x85,
        0x5C,
        0x59,
        0x71,
        0x70,
        0x63,
        0x8A,
        0x8B,
        0x4C,
        0x4E,
        0x7A,
        0xEF,
        0x80,
        0x00,
        0x00
      >>

      parsed = BodyParser.parse(inclusion_ok)

      assert parsed == %{
               command_class: :network_management_inclusion,
               command: :node_add_status,
               seq_no: 0x1C,
               status: :done,
               listening?: false,
               node_id: 0x1D,
               basic_class: :routing_slave,
               generic_class: :entry_control,
               specific_class: :secure_keypad_door_lock,
               command_classes: [
                 :schedule,
                 :manufacturer_specific,
                 :security,
                 :device_rest_locally,
                 :powerlevel,
                 :command_class_version,
                 :zip_naming,
                 :zip,
                 :battery,
                 :door_lock,
                 :association,
                 :ip_association,
                 :association_group_info,
                 :alarm,
                 :configuration,
                 :user_code,
                 :time,
                 :time_parameters,
                 :door_lock_logging,
                 :schedule_entry_lock,
                 :firmware_update_md
               ],
               secure: true,
               keys_granted: [:s0],
               kex_fail_type: :none,
               dsk: "",
               dsk_length: 0x00
             }
    end
  end

  test "node neighbor update status done" do
    inclusion_fail = <<0x34, 0x0C, 0x01, 0x22>>

    parsed = BodyParser.parse(inclusion_fail)

    assert parsed == %{
             command_class: :network_management_inclusion,
             command: :node_neighbor_update_status,
             seq_no: 0x01,
             status: :done
           }
  end

  test "node neighbor update status failed" do
    inclusion_fail = <<0x34, 0x0C, 0x01, 0x23>>

    parsed = BodyParser.parse(inclusion_fail)

    assert parsed == %{
             command_class: :network_management_inclusion,
             command: :node_neighbor_update_status,
             seq_no: 0x01,
             status: :failed
           }
  end

  describe "parses manufacture reports" do
    test "parses manufacture specific report" do
      manufacture_specific_report = <<0x72, 0x05, 0x12, 0x34, 0x56, 0x78, 0x00, 0x01>>
      parsed = BodyParser.parse(manufacture_specific_report)

      assert parsed == %{
               command_class: :manufacturer_specific,
               command: :manufacturer_specific_report,
               manufacturer_id: 0x1234,
               product_type_id: 0x5678,
               product_id: 0x01
             }
    end

    test "parses device specific report" do
      device_specific_report = <<
        0x72,
        0x07,
        # reserved
        0x00::size(5),
        # device id type is serial number
        0x01::size(3),
        # device id data format is utf-8
        0x00::size(3),
        # device id data length is 2
        0x02::size(5),
        # device id data is "PQ"
        0x50,
        0x51
      >>

      parsed = BodyParser.parse(device_specific_report)

      assert parsed == %{
               command_class: :manufacturer_specific,
               command: :device_specific_report,
               value: %{device_id_type: :serial_number, device_id: "PQ"}
             }
    end
  end

  describe "parses node reports" do
    test "parses node list get report" do
      node_list_get_report = <<0x52, 0x02, 0x12, 0x00, 0x01, 0x01, 0x00, 0x00>>
      parsed = BodyParser.parse(node_list_get_report)

      assert parsed === %{
               command_class: :network_management_proxy,
               command: :node_list_report,
               seq_no: 0x12,
               status: 0x00,
               node_list: [1]
             }
    end

    test "parses controller default set complete with status done" do
      binary = <<0x4D, 0x07, 0x01, 0x06>>
      parsed = BodyParser.parse(binary)

      assert parsed == %{
               command_class: NetworkManagementBasic,
               command: :default_set_complete,
               seq_no: 0x01,
               status: :done
             }
    end

    test "parses controller learn mode set with status done and new node id 10" do
      binary = <<0x4D, 0x02, 0x01, 0x06, 0x00, 0x0A, 0, 0, 0, 0, 0, 0, 0, 0>>
      parsed = BodyParser.parse(binary)

      assert parsed == %{
               command_class: NetworkManagementBasic,
               command: :learn_mode_set_status,
               seq_no: 0x01,
               report: %{
                 status: :done,
                 new_node_id: 0x0A
               }
             }
    end

    test "parses controller learn mode set with status failed and new node id 0" do
      binary = <<0x4D, 0x02, 0x01, 0x07, 0x00, 0x00>>
      parsed = BodyParser.parse(binary)

      assert parsed == %{
               command_class: NetworkManagementBasic,
               command: :learn_mode_set_status,
               seq_no: 0x01,
               report: %{
                 status: :failed,
                 new_node_id: 0x00
               }
             }
    end

    test "parses node info cache report" do
      node_info_cache_report = <<0x52, 0x04, 0x12, 0x2, 0x00, 0x00, 0x00, 0x04, 0x08, 0x06, 0x43>>
      parsed = BodyParser.parse(node_info_cache_report)

      assert parsed == %{
               command_class: :network_management_proxy,
               command: :node_info_cache_report,
               report: %{
                 basic_cmd_class: :routing_slave,
                 generic_cmd_class: :thermostat,
                 specific_cmd_class: :thermostat_general_v2,
                 command_classes: [
                   :thermostat_setpoint
                 ],
                 listening?: false,
                 security: :none
               }
             }
    end

    test "parses node info cache report for a listening node" do
      node_info_cache_report = <<0x52, 0x04, 0x12, 0x2, 0x80, 0x00, 0x00, 0x04, 0x08, 0x06, 0x43>>
      parsed = BodyParser.parse(node_info_cache_report)

      assert parsed == %{
               command_class: :network_management_proxy,
               command: :node_info_cache_report,
               report: %{
                 basic_cmd_class: :routing_slave,
                 generic_cmd_class: :thermostat,
                 specific_cmd_class: :thermostat_general_v2,
                 command_classes: [
                   :thermostat_setpoint
                 ],
                 listening?: true,
                 security: :none
               }
             }
    end
  end

  describe "parses binary switch report" do
    test "when state is off" do
      binary_switch_report = <<0x25, 0x03, 0x00>>
      parsed = BodyParser.parse(binary_switch_report)

      assert parsed == %{
               command_class: :switch_binary,
               command: :report,
               value: :off
             }
    end

    test "when state is on" do
      binary_switch_report = <<0x25, 0x03, 0xFF>>
      parsed = BodyParser.parse(binary_switch_report)

      assert parsed == %{
               command_class: :switch_binary,
               command: :report,
               value: :on
             }
    end

    test "when state is unknown" do
      binary_switch_report = <<0x25, 0x03, 0xFE>>
      parsed = BodyParser.parse(binary_switch_report)

      assert parsed == %{
               command_class: :switch_binary,
               command: :report,
               value: :unknown
             }
    end
  end

  describe "parses basic report" do
    test "when value is off" do
      basic_report = <<0x20, 0x03, 0x00>>
      parsed = BodyParser.parse(basic_report)

      assert parsed == %{
               command_class: :basic,
               command: :report,
               value: :off
             }
    end

    test "when value is on" do
      basic_report = <<0x20, 0x03, 0xFF>>
      parsed = BodyParser.parse(basic_report)

      assert parsed == %{
               command_class: :basic,
               command: :report,
               value: :on
             }
    end

    test "when state is unknown" do
      basic_report = <<0x20, 0x03, 0xFE>>
      parsed = BodyParser.parse(basic_report)

      assert parsed == %{
               command_class: :basic,
               command: :report,
               value: :unknown
             }
    end
  end

  describe "parses multilevel switch report" do
    test "when state is off" do
      multilevel_switch_report = <<0x26, 0x03, 0x00>>
      parsed = BodyParser.parse(multilevel_switch_report)

      assert parsed == %{
               command_class: :switch_multilevel,
               command: :report,
               value: :off
             }
    end

    test "when state is on" do
      multilevel_switch_report = <<0x26, 0x03, 0x09>>
      parsed = BodyParser.parse(multilevel_switch_report)

      assert parsed == %{
               command_class: :switch_multilevel,
               command: :report,
               value: 0x09
             }
    end

    test "when state is unknown" do
      multilevel_switch_report = <<0x26, 0x03, 0xFE>>
      parsed = BodyParser.parse(multilevel_switch_report)

      assert parsed == %{
               command_class: :switch_multilevel,
               command: :report,
               value: :unknown
             }
    end
  end

  describe "parses sensor multilevel report" do
    test "parse a sensor_multilevel report" do
      sensor_multilevel_report = <<0x31, 0x05, 0x01, 0x01, 0x50>>
      parsed = BodyParser.parse(sensor_multilevel_report)

      assert parsed == %{
               command_class: :sensor_multilevel,
               command: :report,
               value: %{
                 type: :temperature,
                 level: 80
               }
             }
    end
  end

  describe "parses thermostat reports" do
    test "parse a thermostat mode report" do
      thermostat_mode_report = <<0x40, 0x03, 0x00>>
      parsed = BodyParser.parse(thermostat_mode_report)

      assert parsed == %{
               command_class: :thermostat_mode,
               command: :report,
               value: :off
             }
    end

    test "parse a thermostat fan mode report" do
      thermostat_fan_mode_report = <<0x44, 0x03, 0x00>>
      parsed = BodyParser.parse(thermostat_fan_mode_report)

      assert parsed == %{
               command_class: :thermostat_fan_mode,
               command: :report,
               value: :auto_low
             }
    end

    test "parse a thermostat setpoint report" do
      thermostat_setpoint_report = <<0x43, 0x03, 0x01, 0x01, 0x50>>
      parsed = BodyParser.parse(thermostat_setpoint_report)

      assert parsed == %{
               command_class: :thermostat_setpoint,
               command: :report,
               value: %{
                 type: :heating,
                 value: 80
               }
             }
    end

    test "parse a thermostat fan state report" do
      thermostat_state_report = <<0x45, 0x03, 0x02>>
      parsed = BodyParser.parse(thermostat_state_report)

      assert parsed == %{
               command_class: :thermostat_fan_state,
               command: :report,
               value: :running_high
             }
    end
  end

  test "parse a thermostat setback report" do
    thermostat_state_report = <<0x47, 0x03, 0x00::size(6), 0x02::size(2), 0x79>>
    parsed = BodyParser.parse(thermostat_state_report)

    assert parsed == %{
             command_class: :thermostat_setback,
             command: :report,
             report: %{
               type: :permanent_override,
               state: :frost_protection
             }
           }
  end

  describe "parses door lock reports" do
    test "parse a user code report" do
      user_code_report = <<0x63, 0x03, 0x01, 0x01, 0x31, 0x32, 0x33, 0x34>>
      parsed = BodyParser.parse(user_code_report)

      assert parsed == %{
               command_class: :user_code,
               command: :report,
               value: %{
                 slot_id: 0x01,
                 slot_status: :occupied,
                 code: <<0x31, 0x32, 0x33, 0x34>>
               }
             }
    end

    test "parse a users number report" do
      users_number_report = <<0x63, 0x05, 0x64>>
      parsed = BodyParser.parse(users_number_report)

      assert parsed == %{
               command_class: :user_code,
               command: :users_number_report,
               value: 100
             }
    end

    test "parse an alarm event report" do
      alarm_event_report = <<0x71, 0x05, 0x15, 0x01>>
      parsed = BodyParser.parse(alarm_event_report)

      assert parsed == %{
               command_class: :alarm,
               command: :report,
               value: %{
                 alarm_type: 0x15,
                 alarm_level: 0x01
               }
             }
    end
  end

  describe "parses configuration reports" do
    test "parse configuration report" do
      config_report = <<0x70, 0x06, 0x80, 0x01, 0x00>>
      config_report_with_size = <<0x70, 0x06, 0x80, 0x02, 0x01, 0x02>>

      parsed_no_size = BodyParser.parse(config_report)
      parsed_sized = BodyParser.parse(config_report_with_size)

      assert parsed_no_size == %{
               command_class: Configuration,
               command: :report,
               value: %{
                 param: 0x80,
                 value: 0x00
               }
             }

      assert parsed_sized == %{
               command_class: Configuration,
               command: :report,
               value: %{
                 param: 0x80,
                 value: 0x102
               }
             }
    end
  end

  describe "parse firmware update reports" do
    test "parse a firmware update metadata report" do
      firmware_update_md_report = <<0x7A, 0x02, 0x00, 0x01, 0x00, 0x02, 0x61, 0x62>>
      parsed = BodyParser.parse(firmware_update_md_report)

      assert parsed == %{
               command_class: FirmwareUpdateMD,
               command: :report,
               value: %{
                 manufacturer_id: 1,
                 firmware_id: 2,
                 checksum: "ab"
               }
             }
    end
  end

  describe "parses version report" do
    test "parse a version report" do
      version_report = <<
        0x86,
        0x14,
        0x70,
        0x01
      >>

      parsed = BodyParser.parse(version_report)

      assert parsed == %{
               command_class: CommandClassVersion,
               command: :report,
               value: %{
                 command_class: :configuration,
                 version: 1
               }
             }
    end
  end

  describe "parses meter report" do
    test "parse a meter report" do
      meter_report = <<0x32, 0x02, 33, 84, 0, 0, 0, 0, 1, 45, 0, 0, 0, 0>>
      parsed = BodyParser.parse(meter_report)

      assert parsed == %{
               command_class: :meter,
               command: :meter_report,
               value: %{
                 meter_type: 1,
                 precision: 2,
                 rate_type: 1,
                 reading: 0,
                 scale: 2
               }
             }
    end
  end

  describe "parses time reports" do
    test "parse a time report" do
      time_report = <<0x8A, 0x02, 1, 2, 3>>
      parsed = BodyParser.parse(time_report)

      assert parsed == %{
               command_class: :time,
               command: :time_report,
               value: %{
                 hour: 1,
                 minute: 2,
                 second: 3
               }
             }
    end

    test "parse a date report" do
      date_report = <<0x8A, 0x04, 0x07, 0xE3, 0x0C, 0x19>>
      parsed = BodyParser.parse(date_report)

      assert parsed == %{
               command_class: :time,
               command: :date_report,
               value: %{
                 year: 2019,
                 month: 12,
                 day: 25
               }
             }
    end

    test "parse a time offset report" do
      time_report =
        <<0x8A, 0x07, 0x1::size(1), 4::size(7), 0, 0x0::size(1), 60::size(7), 3, 10, 2, 11, 3, 2>>

      parsed = BodyParser.parse(time_report)

      assert parsed == %{
               command_class: :time,
               command: :time_offset_report,
               value: %{
                 sign_tzo: 1,
                 hour_tzo: 4,
                 minute_tzo: 0,
                 sign_offset_dst: 0,
                 minute_offset_dst: 60,
                 month_start_dst: 3,
                 day_start_dst: 10,
                 hour_start_dst: 2,
                 month_end_dst: 11,
                 day_end_dst: 3,
                 hour_end_dst: 2
               }
             }
    end
  end

  describe "parse power management report for switching ac power" do
    test "disconnected AC" do
      bytes = <<0x71, 0x05, 0x00, 0x00, 0x00, 0xFF, 0x08, 0x02, 0x00>>
      parsed = BodyParser.parse(bytes)

      assert parsed == %{
               command_class: :notification,
               command: :report,
               value: %{
                 notification_type: :power_management,
                 notification_state: :ac_mains_disconnected
               }
             }
    end

    test "re-connected AC" do
      bytes = <<0x71, 0x05, 0x00, 0x00, 0x00, 0xFF, 0x08, 0x03, 0x00>>
      parsed = BodyParser.parse(bytes)

      assert parsed == %{
               command_class: :notification,
               command: :report,
               value: %{
                 notification_type: :power_management,
                 notification_state: :ac_mains_reconnected
               }
             }
    end
  end

  test "parse mailbox configuration report do" do
    bytes = <<105, 3, 25, 1, 244, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 161>>

    expected_report = %{
      command: :mailbox_configuration_report,
      command_class: :mailbox,
      mail_box_capacity: 500,
      mode: :mailbox_service_enabled,
      proxy_support: true,
      service_ip: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      service_support: true,
      udp_port: 3745
    }

    assert BodyParser.parse(bytes) == expected_report
  end

  test "parse wake up interval report" do
    bytes = <<0x84, 0x06, 0x00, 0x00, 0x01, 0x10>>

    expected_report = %{
      command: :wake_up_interval_report,
      command_class: :wake_up,
      value: %{seconds: 1, node_id: 16}
    }

    assert BodyParser.parse(bytes) == expected_report
  end
end
