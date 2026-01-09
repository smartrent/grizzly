defmodule Grizzly.ZWave.Commands.BatteryReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.BatteryReport

  test "creates the command and validates params" do
    params = [level: 50]
    {:ok, _command} = Commands.create(:battery_report, params)
  end

  test "encodes v1 params correctly" do
    params = [level: 0x20]
    {:ok, command} = Commands.create(:battery_report, params)
    expected_binary = <<0x20>>
    assert expected_binary == BatteryReport.encode_params(command)
  end

  test "encodes v2 params correctly" do
    params = [
      level: 0x20,
      charging_status: :charging,
      rechargeable: true,
      backup: false,
      overheating: false,
      low_fluid: false,
      replace_recharge: :soon,
      disconnected: false
    ]

    {:ok, command} = Commands.create(:battery_report, params)

    expected_binary =
      <<0x20, 0x01::2, 0x01::1, 0x00::1, 0x00::1, 0x00::1, 0x01::2, 0x00::7, 0x00::1>>

    assert expected_binary == BatteryReport.encode_params(command)
  end

  test "encodes v3 params correctly" do
    params = [
      level: 0x20,
      charging_status: :charging,
      rechargeable: true,
      backup: false,
      overheating: false,
      low_fluid: false,
      replace_recharge: :soon,
      low_temperature: false,
      disconnected: false
    ]

    {:ok, command} = Commands.create(:battery_report, params)

    expected_binary =
      <<0x20, 0x01::2, 0x01::1, 0x00::1, 0x00::1, 0x00::1, 0x01::2, 0x00::6, 0x00::1, 0x00::1>>

    assert expected_binary == BatteryReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    {:ok, params} = BatteryReport.decode_params(<<0x20>>)
    assert Keyword.get(params, :level) == 0x20

    {:ok, params} = BatteryReport.decode_params(<<0xFF>>)
    assert Keyword.get(params, :level) == 0

    {:ok, params} = BatteryReport.decode_params(<<0>>)
    assert Keyword.get(params, :level) == 0

    {:ok, params} = BatteryReport.decode_params(<<1>>)
    assert Keyword.get(params, :level) == 1

    {:ok, params} = BatteryReport.decode_params(<<100>>)
    assert Keyword.get(params, :level) == 100

    {:ok, params} = BatteryReport.decode_params(<<101>>)
    assert Keyword.get(params, :level) == 100

    {:ok, params} = BatteryReport.decode_params(<<254>>)
    assert Keyword.get(params, :level) == 100
  end

  test "decodes v2 params correctly" do
    binary_params =
      <<0x20, 0x01::2, 0x01::1, 0x00::1, 0x00::1, 0x00::1, 0x01::2, 0x00::7, 0x00::1>>

    {:ok, params} = BatteryReport.decode_params(binary_params)
    assert Keyword.get(params, :charging_status) == :charging
    assert Keyword.get(params, :rechargeable) == true
    assert Keyword.get(params, :backup) == false
    assert Keyword.get(params, :overheating) == false
    assert Keyword.get(params, :low_fluid) == false
    assert Keyword.get(params, :replace_recharge) == :soon
    assert Keyword.get(params, :disconnected) == false
  end

  test "decodes v3 params correctly" do
    binary_params =
      <<0x20, 0x01::2, 0x01::1, 0x00::1, 0x00::1, 0x00::1, 0x01::2, 0x00::6, 0x00::1, 0x00::1>>

    {:ok, params} = BatteryReport.decode_params(binary_params)
    assert Keyword.get(params, :charging_status) == :charging
    assert Keyword.get(params, :rechargeable) == true
    assert Keyword.get(params, :backup) == false
    assert Keyword.get(params, :overheating) == false
    assert Keyword.get(params, :low_fluid) == false
    assert Keyword.get(params, :replace_recharge) == :soon
    assert Keyword.get(params, :low_temperature) == false
    assert Keyword.get(params, :disconnected) == false
  end
end
