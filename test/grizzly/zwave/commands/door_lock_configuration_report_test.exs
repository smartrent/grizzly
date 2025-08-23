defmodule Grizzly.ZWave.Commands.DoorLockConfigurationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.DoorLockConfigurationReport

  describe "creates the command and validates params" do
    test "v1-3" do
      params = [
        operation_type: :constant_operation,
        manual_outside_door_handles: [1, 2],
        manual_inside_door_handles: [3, 4],
        lock_timeout: 65
      ]

      {:ok, _command} = DoorLockConfigurationReport.new(params)
    end

    test "v4" do
      params = [
        operation_type: :constant_operation,
        manual_outside_door_handles: [1, 2],
        manual_inside_door_handles: [3, 4],
        lock_timeout: 65,
        auto_relock_time: 125,
        hold_and_release_time: 126,
        block_to_block?: true,
        twist_assist?: false
      ]

      {:ok, _command} = DoorLockConfigurationReport.new(params)
    end
  end

  describe "encodes params correctly" do
    test "v1-3" do
      params = [
        operation_type: :constant_operation,
        manual_outside_door_handles: [1, 2],
        manual_inside_door_handles: [3, 4],
        lock_timeout: 65
      ]

      {:ok, command} = DoorLockConfigurationReport.new(params)
      expected_params_binary = DoorLockConfigurationReport.encode_params(command)
      assert <<0x01, 0x03::4, 0x0C::4, 0x01, 0x05>> == expected_params_binary
    end

    test "v4" do
      params = [
        operation_type: :constant_operation,
        manual_outside_door_handles: [1, 2],
        manual_inside_door_handles: [3, 4],
        lock_timeout: 65,
        auto_relock_time: 125,
        hold_and_release_time: 30,
        block_to_block?: true,
        twist_assist?: false
      ]

      {:ok, command} = DoorLockConfigurationReport.new(params)
      expected_params_binary = DoorLockConfigurationReport.encode_params(command)

      assert <<0x01, 0x03::4, 0x0C::4, 0x01, 0x05, 125::16, 30::16, 0x00::6, 0x01::1, 0x00::1>> ==
               expected_params_binary
    end
  end

  describe "decodes params correctly" do
    test "v1-3" do
      params_binary = <<0x01, 0x03::4, 0x0C::4, 0x01, 0x05>>
      {:ok, params} = DoorLockConfigurationReport.decode_params(params_binary)
      assert Keyword.get(params, :operation_type) == :constant_operation
      assert Enum.sort(Keyword.get(params, :manual_outside_door_handles)) == [1, 2]
      assert Enum.sort(Keyword.get(params, :manual_inside_door_handles)) == [3, 4]
      assert Keyword.get(params, :lock_timeout) == 65
    end

    test "v4" do
      params_binary =
        <<0x01, 0x03::4, 0x0C::4, 0x01, 0x05, 125::16, 30::16, 0x00::6, 0x01::1, 0x00::1>>

      {:ok, params} = DoorLockConfigurationReport.decode_params(params_binary)
      assert Keyword.get(params, :operation_type) == :constant_operation
      assert Enum.sort(Keyword.get(params, :manual_outside_door_handles)) == [1, 2]
      assert Enum.sort(Keyword.get(params, :manual_inside_door_handles)) == [3, 4]
      assert Keyword.get(params, :lock_timeout) == 65
      assert Keyword.get(params, :auto_relock_time) == 125
      assert Keyword.get(params, :hold_and_release_time) == 30
      assert Keyword.get(params, :block_to_block?) == true
      assert Keyword.get(params, :twist_assist?) == false
    end
  end
end
