defmodule Grizzly.ZWave.Commands.SwitchMultilevelReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SwitchMultilevelReport

  test "creates the command and validates params" do
    params = [value: :off]
    {:ok, _command} = SwitchMultilevelReport.new(params)
  end

  test "encodes v1 params correctly" do
    params = [value: 99]
    {:ok, command} = SwitchMultilevelReport.new(params)
    expected_binary = <<0x63>>
    assert expected_binary == SwitchMultilevelReport.encode_params(command)
  end

  test "encodes v2 params correctly" do
    params = [value: 99, duration: 10]
    {:ok, command} = SwitchMultilevelReport.new(params)
    expected_binary = <<0x63, 0x0A>>
    assert expected_binary == SwitchMultilevelReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 100
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x32, 0x0A>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 0x32
    assert Keyword.get(params, :duration) == 0x0A
  end
end
