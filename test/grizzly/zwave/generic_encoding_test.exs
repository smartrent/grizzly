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
        {:central_scene_configuration_report, [slow_refresh: true], <<0x5B, 0x06, 0x80>>},
        {:central_scene_configuration_report, [slow_refresh: false], <<0x5B, 0x06, 0x00>>}
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
