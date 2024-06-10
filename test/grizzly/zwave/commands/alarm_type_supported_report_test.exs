defmodule Grizzly.ZWave.Commands.AlarmTypeSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmTypeSupportedReport

  test "creates the command and validates params" do
    params = [types: [:smoke_alarm, :home_security, :siren, :gas_alarm]]
    {:ok, _command} = AlarmTypeSupportedReport.new(params)
  end

  test "encodes params correctly" do
    params = [types: [:smoke_alarm, :home_security, :siren, :gas_alarm]]
    {:ok, command} = AlarmTypeSupportedReport.new(params)
    expected_binary = <<0x00::3, 0x03::5, 0b10000010, 0b01000000, 0b00000100>>
    assert expected_binary == AlarmTypeSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x03::5, 0b10000010, 0b01000000, 0b00000100>>
    {:ok, params} = AlarmTypeSupportedReport.decode_params(binary_params)

    assert Enum.sort([:smoke_alarm, :home_security, :siren, :gas_alarm]) ==
             Enum.sort(Keyword.get(params, :types))
  end
end
