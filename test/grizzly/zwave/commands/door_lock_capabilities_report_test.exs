defmodule Grizzly.ZWave.Commands.DoorLockCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.DoorLockCapabilitiesReport

  test "creates the command and validates params" do
    params = [
      supported_operations: [:constant_operation, :timed_operation],
      supported_door_lock_modes: [:unsecured, :secured],
      configurable_outside_handles: [1, 2],
      configurable_inside_handles: [3, 4],
      supported_door_components: [:latch, :bolt],
      auto_relock_supported?: true,
      hold_and_release_supported?: true,
      twist_assist_supported?: false,
      block_to_block_supported?: false
    ]

    {:ok, _command} = Commands.create(:door_lock_capabilities_report, params)
  end

  test "encodes params correctly" do
    params = [
      supported_operations: [:constant_operation, :timed_operation],
      supported_door_lock_modes: [:unsecured, :secured],
      configurable_outside_handles: [1, 2],
      configurable_inside_handles: [3, 4],
      supported_door_components: [:latch, :bolt],
      auto_relock_supported?: true,
      hold_and_release_supported?: true,
      twist_assist_supported?: false,
      block_to_block_supported?: false
    ]

    {:ok, command} = Commands.create(:door_lock_capabilities_report, params)

    expected_params_binary =
      <<0x00::3, 0x01::5, 0x06, 0x02, 0x00, 0xFF, 0x03::4, 0x0C::4, 0x06, 0x00::4, 0x01::1,
        0x01::1, 0x00::1, 0x00::1>>

    assert expected_params_binary == DoorLockCapabilitiesReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary =
      <<0x00::3, 0x01::5, 0x06, 0x02, 0x00, 0xFF, 0x03::4, 0x0C::4, 0x06, 0x00::4, 0x01::1,
        0x01::1, 0x00::1, 0x00::1>>

    {:ok, params} = DoorLockCapabilitiesReport.decode_params(params_binary)
    assert Keyword.get(params, :supported_operations) == [:constant_operation, :timed_operation]
    assert Enum.sort(Keyword.get(params, :supported_door_lock_modes)) == [:secured, :unsecured]
    assert Enum.sort(Keyword.get(params, :configurable_outside_handles)) == [1, 2]
    assert Enum.sort(Keyword.get(params, :configurable_inside_handles)) == [3, 4]
    assert Enum.sort(Keyword.get(params, :supported_door_components)) == [:bolt, :latch]
    assert Keyword.get(params, :auto_relock_supported?) == true
    assert Keyword.get(params, :hold_and_release_supported?) == true
    assert Keyword.get(params, :twist_assist_supported?) == false
    assert Keyword.get(params, :block_to_block_supported?) == false
  end
end
