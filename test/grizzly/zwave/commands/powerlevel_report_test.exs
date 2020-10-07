defmodule Grizzly.ZWave.Commands.PowerlevelReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PowerlevelReport

  test "creates the command and validates params" do
    params = [power_level: :normal_power, timeout: 10]
    {:ok, _command} = PowerlevelReport.new(params)
  end

  test "encodes params correctly" do
    params = [power_level: :normal_power, timeout: 10]
    {:ok, command} = PowerlevelReport.new(params)
    expected_params_binary = <<0x00, 0x0A>>
    assert expected_params_binary == PowerlevelReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00, 0x0A>>
    {:ok, params} = PowerlevelReport.decode_params(params_binary)
    assert Keyword.get(params, :power_level) == :normal_power
    assert Keyword.get(params, :timeout) == 10
  end
end
