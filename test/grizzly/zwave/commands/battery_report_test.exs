defmodule Grizzly.ZWave.Commands.BatteryReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BatteryReport

  test "creates the command and validates params" do
    params = [level: 50]
    {:ok, _command} = BatteryReport.new(params)
  end

  test "encodes v1 params correctly" do
    params = [level: 0x20]
    {:ok, command} = BatteryReport.new(params)
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

    {:ok, command} = BatteryReport.new(params)

    expected_binary =
      <<0x20, 0x01::size(2), 0x01::size(1), 0x00::size(1), 0x00::size(1), 0x00::size(1),
        0x01::size(2), 0x00::size(7), 0x00::size(1)>>

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

    {:ok, command} = BatteryReport.new(params)

    expected_binary =
      <<0x20, 0x01::size(2), 0x01::size(1), 0x00::size(1), 0x00::size(1), 0x00::size(1),
        0x01::size(2), 0x00::size(6), 0x00::size(1), 0x00::size(1)>>

    assert expected_binary == BatteryReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0x20>>
    {:ok, params} = BatteryReport.decode_params(binary_params)
    assert Keyword.get(params, :level) == 0x20
  end

  test "decodes v2 params correctly" do
    binary_params =
      <<0x20, 0x01::size(2), 0x01::size(1), 0x00::size(1), 0x00::size(1), 0x00::size(1),
        0x01::size(2), 0x00::size(7), 0x00::size(1)>>

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
      <<0x20, 0x01::size(2), 0x01::size(1), 0x00::size(1), 0x00::size(1), 0x00::size(1),
        0x01::size(2), 0x00::size(6), 0x00::size(1), 0x00::size(1)>>

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
