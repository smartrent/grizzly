defmodule Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesReport

  test "creates the v2 command and validates params" do
    params = [
      minimum_seconds: 1000,
      maximum_seconds: 2000,
      default_seconds: 1500,
      step_seconds: 500
    ]

    {:ok, _command} = Commands.create(:wake_up_interval_capabilities_report, params)
  end

  test "creates the v3 command and validates params" do
    params = [
      minimum_seconds: 1000,
      maximum_seconds: 2000,
      default_seconds: 1500,
      step_seconds: 500,
      on_demand: true
    ]

    {:ok, _command} = Commands.create(:wake_up_interval_capabilities_report, params)
  end

  test "encodes v2 params correctly" do
    params = [
      minimum_seconds: 1000,
      maximum_seconds: 2000,
      default_seconds: 1500,
      step_seconds: 500
    ]

    {:ok, command} = Commands.create(:wake_up_interval_capabilities_report, params)
    expected_binary = <<0x00, 0x03, 0xE8, 0x00, 0x07, 0xD0, 0x00, 0x05, 0xDC, 0x00, 0x01, 0xF4>>
    assert expected_binary == WakeUpIntervalCapabilitiesReport.encode_params(nil, command)
  end

  test "encodes v3 params correctly" do
    params = [
      minimum_seconds: 1000,
      maximum_seconds: 2000,
      default_seconds: 1500,
      step_seconds: 500,
      on_demand: true
    ]

    {:ok, command} = Commands.create(:wake_up_interval_capabilities_report, params)

    expected_binary =
      <<0x00, 0x03, 0xE8, 0x00, 0x07, 0xD0, 0x00, 0x05, 0xDC, 0x00, 0x01, 0xF4, 0x00::7, 0x01::1>>

    assert expected_binary == WakeUpIntervalCapabilitiesReport.encode_params(nil, command)
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x00, 0x03, 0xE8, 0x00, 0x07, 0xD0, 0x00, 0x05, 0xDC, 0x00, 0x01, 0xF4>>
    {:ok, params} = WakeUpIntervalCapabilitiesReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :minimum_seconds) == 1000
    assert Keyword.get(params, :maximum_seconds) == 2000
    assert Keyword.get(params, :default_seconds) == 1500
    assert Keyword.get(params, :step_seconds) == 500
  end

  test "decodes v3 params correctly" do
    binary_params =
      <<0x00, 0x03, 0xE8, 0x00, 0x07, 0xD0, 0x00, 0x05, 0xDC, 0x00, 0x01, 0xF4, 0x01>>

    {:ok, params} = WakeUpIntervalCapabilitiesReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :minimum_seconds) == 1000
    assert Keyword.get(params, :maximum_seconds) == 2000
    assert Keyword.get(params, :default_seconds) == 1500
    assert Keyword.get(params, :step_seconds) == 500
    assert Keyword.get(params, :on_demand) == true
  end
end
