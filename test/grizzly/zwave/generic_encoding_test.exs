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
         <<0x66, 0x08, 0x01, 0xFF>>}
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
