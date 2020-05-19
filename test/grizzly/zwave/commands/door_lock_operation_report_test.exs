defmodule Grizzly.ZWave.Commands.DoorLockOperationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.DoorLockOperationReport

  describe "creates the command and validates params" do
    test "with defaults" do
      {:ok, command} = DoorLockOperationReport.new(mode: :unsecured)

      assert Command.param!(command, :outside_handles_mode) == handles_default()
      assert Command.param!(command, :inside_handles_mode) == handles_default()
      assert Command.param!(command, :latch_position) == :open
      assert Command.param!(command, :bolt_position) == :locked
      assert Command.param!(command, :door_state) == :open
      assert Command.param!(command, :timeout_minutes) == 0
      assert Command.param!(command, :timeout_seconds) == 0
    end

    test "override defaults" do
      {:ok, command} = DoorLockOperationReport.new(mode: :unsecured, latch_position: :closed)

      assert Command.param!(command, :latch_position) == :closed
    end
  end

  describe "encodes params correctly" do
    test "defaults" do
      {:ok, command} = DoorLockOperationReport.new(mode: :secured)

      expected_binary = <<0x62, 0x03, 0xFF, 0x00, 0x00, 0x00, 0x00>>

      assert expected_binary == ZWave.to_binary(command)
    end

    test "with custom params" do
      {:ok, command} =
        DoorLockOperationReport.new(
          mode: :unsecured,
          latch_position: :closed,
          timeout_minutes: 120,
          outside_handles_mode: %{1 => :enabled, 2 => :disabled, 3 => :enabled, 4 => :enabled}
        )

      expected_binary = <<0x62, 0x03, 0x00, 0xD0, 0x04, 0x78, 0x00>>

      assert expected_binary == ZWave.to_binary(command)
    end
  end

  describe "decodes params correctly" do
    test "basic mode" do
      binary = <<0x62, 0x03, 0xFF, 0x00, 0x00, 0x00, 0x00>>

      {:ok, command} = ZWave.from_binary(binary)

      assert Command.param!(command, :mode) == :secured
    end

    test "with some other options" do
      binary = <<0x62, 0x03, 0x00, 0xD0, 0x04, 0x78, 0x00>>

      {:ok, command} = ZWave.from_binary(binary)
      assert Command.param!(command, :mode) == :unsecured
      assert Command.param!(command, :latch_position) == :closed
      assert Command.param!(command, :timeout_minutes) == 120

      assert Command.param!(command, :outside_handles_mode) == %{
               1 => :enabled,
               2 => :disabled,
               3 => :enabled,
               4 => :enabled
             }
    end
  end

  describe "encodes v4 params correctly" do
    test "with custom params" do
      {:ok, command} =
        DoorLockOperationReport.new(
          mode: :unsecured,
          latch_position: :closed,
          timeout_minutes: 120,
          outside_handles_mode: %{1 => :enabled, 2 => :disabled, 3 => :enabled, 4 => :enabled},
          target_mode: :unsecured,
          duration: 0
        )

      expected_binary = <<0x62, 0x03, 0x00, 0xD0, 0x04, 0x78, 0x00, 0x00, 0x00>>

      assert expected_binary == ZWave.to_binary(command)
    end
  end

  describe "decodes v4 params correctly" do
    test "with some other options" do
      binary = <<0x62, 0x03, 0x00, 0xD0, 0x04, 0x78, 0x00, 0x00, 0x00>>

      {:ok, command} = ZWave.from_binary(binary)
      assert Command.param!(command, :mode) == :unsecured
      assert Command.param!(command, :latch_position) == :closed
      assert Command.param!(command, :timeout_minutes) == 120

      assert Command.param!(command, :outside_handles_mode) == %{
               1 => :enabled,
               2 => :disabled,
               3 => :enabled,
               4 => :enabled
             }

      assert Command.param!(command, :target_mode) == :unsecured
      assert Command.param!(command, :duration) == 0
    end
  end

  defp handles_default(), do: %{1 => :disabled, 2 => :disabled, 3 => :disabled, 4 => :disabled}
end
