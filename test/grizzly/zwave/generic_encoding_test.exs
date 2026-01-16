defmodule Grizzly.ZWave.GenericEncodingTest do
  use ExUnit.Case,
    async: true,
    parameterize:
      [
        {:alarm_event_supported_get, [type: :access_control], <<0x71, 0x01, 0x06>>},
        {:alarm_set, [zwave_type: :home_security, status: :enabled], <<0x71, 0x06, 0x07, 0xFF>>},
        {:all_users_checksum_report, [checksum: 0x7FFF], <<0x83, 0x15, 0x7F, 0xFF>>},
        {:application_busy, [status: :try_again_after_wait, wait_time: 10],
         <<0x22, 0x01, 0x01, 0x0A>>},
        {:application_rejected_request, [], <<0x22, 0x02, 0x00>>},
        {:central_scene_configuration_set, [slow_refresh: true], <<0x5B, 0x04, 0x80>>},
        {:central_scene_configuration_set, [slow_refresh: false], <<0x5B, 0x04, 0x00>>},
        {:central_scene_configuration_report, [slow_refresh: true], <<0x5B, 0x06, 0x80>>},
        {:central_scene_configuration_report, [slow_refresh: false], <<0x5B, 0x06, 0x00>>},
        {:association_get, [grouping_identifier: 2], <<0x85, 0x02, 0x02>>},
        {:association_groupings_report, [supported_groupings: 3], <<0x85, 0x06, 0x03>>},
        {:association_specific_group_report, [group: 5], <<0x85, 0x0C, 0x05>>},
        {:association_group_info_get, [refresh_cache: false, all: false],
         <<0x59, 0x03, 0x00, 0x00>>},
        {:association_group_info_get, [refresh_cache: true, all: false],
         <<0x59, 0x03, 0x80, 0x00>>},
        {:association_group_info_get, [refresh_cache: false, all: true],
         <<0x59, 0x03, 0x40, 0x00>>},
        {:association_group_info_get, [refresh_cache: true, all: true, group_id: 10],
         <<0x59, 0x03, 0xC0, 0x0A>>},
        {:association_group_command_list_get, [allow_cache: true, group_id: 4],
         <<0x59, 0x05, 0x80, 0x04>>},
        {:association_group_command_list_get, [allow_cache: false, group_id: 9],
         <<0x59, 0x05, 0x00, 0x09>>},
        {:barrier_operator_set, [target_value: :open], <<0x66, 0x01, 0xFF>>},
        {:barrier_operator_set, [target_value: :close], <<0x66, 0x01, 0x00>>},
        {:barrier_operator_report, [state: :open], <<0x66, 0x03, 0xFF>>},
        {:barrier_operator_report, [state: :closed], <<0x66, 0x03, 0x00>>},
        {:barrier_operator_report, [state: 50], <<0x66, 0x03, 0x32>>},
        {:barrier_operator_signal_set,
         [subsystem_type: :audible_notification, subsystem_state: :on],
         <<0x66, 0x06, 0x01, 0xFF>>},
        {:barrier_operator_signal_get, [subsystem_type: :audible_notification],
         <<0x66, 0x07, 0x01>>},
        {:barrier_operator_signal_get, [subsystem_type: :visual_notification],
         <<0x66, 0x07, 0x02>>},
        {:barrier_operator_signal_report,
         [subsystem_type: :audible_notification, subsystem_state: :on],
         <<0x66, 0x08, 0x01, 0xFF>>},
        {:configuration_bulk_get, [number_of_parameters: 3, offset: 2],
         <<0x70, 0x08, 0x02::16, 0x03>>},
        {:configuration_get, [param_number: 2], <<0x70, 0x05, 0x02>>},
        {:configuration_name_get, [param_number: 3], <<0x70, 0x0A, 0x03::16>>},
        {:configuration_info_get, [param_number: 4], <<0x70, 0x0C, 0x04::16>>},
        {:configuration_properties_get, [param_number: 5], <<0x70, 0x0E, 0x05::16>>},
        {:clock_set, [weekday: :monday, hour: 12, minute: 30],
         <<0x81, 0x04, 0x01::3, 12::5, 30>>},
        {:clock_set, [weekday: :saturday, hour: 23, minute: 59],
         <<0x81, 0x04, 0x06::3, 23::5, 59>>},
        {:clock_report, [weekday: :monday, hour: 12, minute: 30],
         <<0x81, 0x06, 0x01::3, 12::5, 30>>},
        {:credential_get, [user_id: 1, credential_type: :uwb, credential_slot: 2],
         <<0x83, 0x0B, 1::16, 0x06, 2::16>>},
        {:credential_learn_start,
         [
           user_id: 1,
           credential_type: :password,
           credential_slot: 2,
           operation_type: :modify,
           learn_timeout: 30
         ], <<0x83, 0x0F, 1::16, 0x02, 2::16, 1, 30>>},
        {:date_report, [year: 2020, month: 7, day: 16], <<0x8A, 0x04, 2020::16, 7, 16>>},
        {:door_lock_operation_set, [mode: :secured], <<0x62, 0x01, 0xFF>>},
        {:door_lock_operation_set, [mode: :unsecured], <<0x62, 0x01, 0x00>>},
        {:dsk_get, [seq_number: 1, add_mode: :learn], <<0x4D, 0x08, 0x01, 0x00>>},
        {:dsk_get, [seq_number: 1, add_mode: :add], <<0x4D, 0x08, 0x01, 0x01>>},
        {:firmware_update_md_get, [number_of_reports: 2, report_number: 128],
         <<0x7A, 0x05, 2, 0x0080::16>>},
        {:manufacturer_specific_report,
         [manufacturer_id: 1, product_type_id: 0xFFFF, product_id: 0x11],
         <<0x72, 0x05, 1::16, 0xFFFF::16, 0x11::16>>},
        {:multi_channel_aggregated_members_get, [aggregated_end_point: 1],
         <<0x60, 0x0E, 0x00::1, 0x01::7>>},
        {:multi_channel_capability_get, [end_point: 2], <<0x60, 0x09, 0x02>>},
        {:network_update_request_status, [seq_number: 2, status: :done],
         <<0x4D, 0x04, 0x02, 0x00>>},
        {:node_provisioning_list_iteration_get, [seq_number: 5, remaining_counter: 255],
         <<0x78, 0x03, 5, 0xFF>>},
        {:node_provisioning_list_iteration_get, [seq_number: 5, remaining_counter: 10],
         <<0x78, 0x03, 5, 10>>},
        {:schedule_entry_lock_daily_repeating_get, [user_identifier: 1, schedule_slot_id: 2],
         <<0x4E, 0x0E, 1, 2>>},
        {:schedule_entry_lock_enable_set, [user_identifier: 100, enabled: true],
         <<0x4E, 0x01, 100, 0x01>>},
        {:schedule_entry_lock_enable_set, [user_identifier: 100, enabled: false],
         <<0x4E, 0x01, 100, 0x00>>},
        {:schedule_entry_lock_enable_all_set, [enabled: true], <<0x4E, 0x02, 0x01>>},
        {:schedule_entry_lock_enable_all_set, [enabled: false], <<0x4E, 0x02, 0x00>>},
        {:schedule_entry_lock_time_offset_report,
         [
           sign_tzo: :minus,
           hour_tzo: 4,
           minute_tzo: 20,
           sign_offset_dst: :plus,
           minute_offset_dst: 100
         ], <<0x4E, 0x0C, 1::1, 4::7, 20::8, 0::1, 100::7>>},
        {:schedule_entry_lock_time_offset_set,
         [
           sign_tzo: :minus,
           hour_tzo: 4,
           minute_tzo: 20,
           sign_offset_dst: :plus,
           minute_offset_dst: 100
         ], <<0x4E, 0x0D, 1::1, 4::7, 20::8, 0::1, 100::7>>},
        {:schedule_entry_lock_week_day_get, [user_identifier: 10, schedule_slot_id: 5],
         <<0x4E, 0x04, 10, 5>>},
        {:schedule_entry_lock_week_day_report,
         [
           user_identifier: 10,
           schedule_slot_id: 5,
           day_of_week: 3,
           start_hour: 9,
           start_minute: 30,
           stop_hour: 17,
           stop_minute: 45
         ], <<0x4E, 0x05, 10, 5, 3, 9, 30, 17, 45>>},
        {:schedule_entry_lock_week_day_set,
         [
           set_action: :modify,
           user_identifier: 10,
           schedule_slot_id: 5,
           day_of_week: 3,
           start_hour: 9,
           start_minute: 30,
           stop_hour: 17,
           stop_minute: 45
         ], <<0x4E, 0x03, 0x01, 10, 5, 3, 9, 30, 17, 45>>},
        {:schedule_entry_lock_year_day_get, [user_identifier: 10, schedule_slot_id: 5],
         <<0x4E, 0x07, 10, 5>>},
        {:schedule_entry_lock_year_day_report,
         [
           user_identifier: 20,
           schedule_slot_id: 5,
           start_year: 97,
           start_month: 10,
           start_day: 7,
           start_hour: 2,
           start_minute: 42,
           stop_year: 99,
           stop_month: 12,
           stop_day: 31,
           stop_hour: 2,
           stop_minute: 42
         ], <<0x4E, 0x08, 20, 5, 97, 10, 7, 2, 42, 99, 12, 31, 2, 42>>},
        {:schedule_entry_lock_year_day_set,
         [
           set_action: :modify,
           user_identifier: 20,
           schedule_slot_id: 5,
           start_year: 97,
           start_month: 10,
           start_day: 7,
           start_hour: 2,
           start_minute: 42,
           stop_year: 99,
           stop_month: 12,
           stop_day: 31,
           stop_hour: 2,
           stop_minute: 42
         ], <<0x4E, 0x06, 0x01, 20, 5, 97, 10, 7, 2, 42, 99, 12, 31, 2, 42>>},
        {:schedule_entry_type_supported_report,
         [
           number_of_slots_week_day: 5,
           number_of_slots_year_day: 10,
           number_of_slots_daily_repeating: 15
         ], <<0x4E, 0x0A, 5, 10, 15>>},
        {:schedule_entry_type_supported_report,
         [
           number_of_slots_week_day: 5,
           number_of_slots_year_day: 10
         ], <<0x4E, 0x0A, 5, 10>>},
        {:thermostat_fan_mode_set, [mode: :auto_high], <<0x44, 0x01, 0x02>>},
        {:thermostat_fan_mode_report, [mode: :auto_high], <<0x44, 0x03, 0x02>>},
        {:thermostat_fan_state_report, [state: :running_high], <<0x45, 0x03, 0x02>>},
        {:thermostat_operating_state_report, [state: :cooling], <<0x42, 0x03, 0x02>>},
        {:thermostat_setpoint_get, [type: :heating], <<0x43, 0x02, 0x01>>},
        {:time_offset_set,
         [
           sign_tzo: :minus,
           hour_tzo: 4,
           minute_tzo: 0,
           sign_offset_dst: :plus,
           minute_offset_dst: 60,
           month_start_dst: 3,
           day_start_dst: 23,
           hour_start_dst: 2,
           month_end_dst: 10,
           day_end_dst: 22,
           hour_end_dst: 2
         ], <<0x8A, 0x05, 0x01::1, 4::7, 0, 0x00::1, 60::7, 3, 23, 2, 10, 22, 2>>},
        {:time_offset_report,
         [
           sign_tzo: :minus,
           hour_tzo: 4,
           minute_tzo: 0,
           sign_offset_dst: :plus,
           minute_offset_dst: 60,
           month_start_dst: 3,
           day_start_dst: 23,
           hour_start_dst: 2,
           month_end_dst: 10,
           day_end_dst: 22,
           hour_end_dst: 2
         ], <<0x8A, 0x07, 0x01::1, 4::7, 0, 0x00::1, 60::7, 3, 23, 2, 10, 22, 2>>},
        {:time_parameters_set,
         [year: 2020, month: 7, day: 17, hour_utc: 14, minute_utc: 30, second_utc: 45],
         <<0x8B, 0x01, 2020::16, 7, 17, 14, 30, 45>>},
        {:time_parameters_report,
         [year: 2020, month: 7, day: 17, hour_utc: 14, minute_utc: 30, second_utc: 45],
         <<0x8B, 0x03, 2020::16, 7, 17, 14, 30, 45>>},
        {:user_code_checksum_report, [checksum: 0xEAAD], <<0x63, 0x12, 0xEA, 0xAD>>},
        {:user_code_users_number_report, [supported_users: 20], <<0x63, 0x05, 20>>},
        {:user_code_users_number_report, [supported_users: 20, extended_supported_users: 300],
         <<0x63, 0x05, 20, 300::16>>},
        {:wake_up_interval_set, [seconds: 1000, node_id: 1], <<0x84, 0x04, 1000::24, 1>>},
        {:wake_up_interval_report, [seconds: 2000, node_id: 1], <<0x84, 0x06, 2000::24, 1>>}
      ]
      |> Enum.map(fn {command_name, params, expected_binary} ->
        %{
          command_name: command_name,
          params: params,
          expected_binary: expected_binary
        }
      end)

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  test "encodes properly", %{
    command_name: command_name,
    params: params,
    expected_binary: expected_binary
  } do
    assert {:ok, command} = Commands.create(command_name, params)

    assert i(expected_binary) == i(Grizzly.ZWave.to_binary(command))
  end

  test "decodes properly", %{
    command_name: command_name,
    params: params,
    expected_binary: expected_binary
  } do
    assert {:ok, command} = Grizzly.ZWave.from_binary(expected_binary)

    assert command.name == command_name

    Enum.each(params, fn {key, value} ->
      assert Command.param!(command, key) == value
    end)
  end

  defp i(value), do: inspect(value, binaries: :as_binaries)
end
