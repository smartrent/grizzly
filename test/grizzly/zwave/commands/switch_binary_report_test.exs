defmodule Grizzly.ZWave.Commands.SwitchBinaryReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.SwitchBinaryReport

  describe "Support V1" do
    test "encodes correctly on" do
      {:ok, report} = SwitchBinaryReport.new(target_value: :on)

      assert <<0x25, 0x03, 0xFF>> == ZWave.to_binary(report)
    end

    test "encodes correctly off" do
      {:ok, report} = SwitchBinaryReport.new(target_value: :off)

      assert <<0x25, 0x03, 0x00>> == ZWave.to_binary(report)
    end

    test "encodes correctly unknown" do
      {:ok, report} = SwitchBinaryReport.new(target_value: :unknown)

      assert <<0x25, 0x03, 0xFE>> == ZWave.to_binary(report)
    end

    test "encodes duration param correctly" do
      params = [current_value: :on, target_value: :off, duration: 10]
      {:ok, command} = SwitchBinaryReport.new(params)
      expected_binary = <<0xFF, 0x00, 0x0A>>
      assert expected_binary == SwitchBinaryReport.encode_params(command)

      params = [current_value: :on, target_value: :off, duration: :default]
      {:ok, command} = SwitchBinaryReport.new(params)
      expected_binary = <<0xFF, 0x00, 0xFF>>
      assert expected_binary == SwitchBinaryReport.encode_params(command)

      params = [current_value: :on, target_value: :off, duration: 180]
      {:ok, command} = SwitchBinaryReport.new(params)
      expected_binary = <<0xFF, 0x00, 0x82>>
      assert expected_binary == SwitchBinaryReport.encode_params(command)
    end

    test "decodes correctly on" do
      binary = <<0x25, 0x03, 0xFF>>
      expected_report = SwitchBinaryReport.new(target_value: :on)

      assert expected_report == ZWave.from_binary(binary)
    end

    test "decodes correctly off" do
      binary = <<0x25, 0x03, 0x00>>
      expected_report = SwitchBinaryReport.new(target_value: :off)

      assert expected_report == ZWave.from_binary(binary)
    end

    test "decodes correctly unknown" do
      binary = <<0x25, 0x03, 0xFE>>
      expected_report = SwitchBinaryReport.new(target_value: :unknown)

      assert expected_report == ZWave.from_binary(binary)
    end
  end

  describe "Support V2" do
    test "encodes correctly on" do
      {:ok, report} = SwitchBinaryReport.new(target_value: :on, duration: 0, current_value: :off)

      assert <<0x25, 0x03, 0x00, 0xFF, 0x00>> == ZWave.to_binary(report)
    end

    test "encodes correctly off" do
      {:ok, report} = SwitchBinaryReport.new(target_value: :off, duration: 0, current_value: :on)

      assert <<0x25, 0x03, 0xFF, 0x00, 0x00>> == ZWave.to_binary(report)
    end

    test "encodes correctly unknown" do
      {:ok, report} =
        SwitchBinaryReport.new(target_value: :unknown, duration: 0, current_value: :off)

      assert <<0x25, 0x03, 0x00, 0xFE, 0x00>> == ZWave.to_binary(report)
    end

    test "decodes correctly on" do
      binary = <<0x25, 0x03, 0x00, 0xFF, 0x00>>

      expected_report =
        SwitchBinaryReport.new(target_value: :on, duration: 0, current_value: :off)

      assert expected_report == ZWave.from_binary(binary)
    end

    test "decodes correctly off" do
      binary = <<0x25, 0x03, 0xFF, 0x00, 0x00>>

      expected_report =
        SwitchBinaryReport.new(target_value: :off, duration: 0x00, current_value: :on)

      assert expected_report == ZWave.from_binary(binary)
    end

    test "decodes correctly unknown" do
      binary = <<0x25, 0x03, 0xFE, 0xFE, 0x00>>

      expected_report =
        SwitchBinaryReport.new(target_value: :unknown, duration: 0x00, current_value: :unknown)

      assert expected_report == ZWave.from_binary(binary)
    end
  end
end
