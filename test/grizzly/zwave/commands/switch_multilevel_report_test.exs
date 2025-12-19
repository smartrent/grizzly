defmodule Grizzly.ZWave.Commands.SwitchMultilevelReportTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

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

    params = [value: 99, duration: :default]
    {:ok, command} = SwitchMultilevelReport.new(params)
    expected_binary = <<0x63, 0xFF>>
    assert expected_binary == SwitchMultilevelReport.encode_params(command)

    params = [value: 99, duration: 180]
    {:ok, command} = SwitchMultilevelReport.new(params)
    expected_binary = <<0x63, 0x82>>
    assert expected_binary == SwitchMultilevelReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 99
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x32, 0x0A>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 0x32
    assert Keyword.get(params, :duration) == 0x0A

    binary_params = <<0x32, 0xFF>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 0x32
    assert Keyword.get(params, :duration) == :default

    binary_params = <<0x32, 0x81>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 0x32
    assert Keyword.get(params, :duration) == 120
  end

  test "decodes v4 params correctly" do
    binary_params = <<0x32, 0x63, 0x0A>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == 50
    assert Keyword.get(params, :target_value) == 99
    assert Keyword.get(params, :duration) == 10
  end

  test "ignores bytes trailing bytes" do
    {result, log} =
      with_log(fn ->
        SwitchMultilevelReport.decode_params(<<0x32, 0x63, 0x0, 0x87>>)
      end)

    assert {:ok, [value: 50, target_value: 99, duration: 0]} = result

    assert log =~ "Unexpected trailing bytes in SwitchMultilevelReport: <<135>>"
  end

  test "decodes Leviton DZ1KD-1BZ dimmer" do
    binary_params = <<100, 100>>
    {:ok, params} = SwitchMultilevelReport.decode_params(binary_params)

    # Fix the 100% report to 99
    assert Keyword.get(params, :value) == 99
    assert Keyword.get(params, :duration) == 100
  end
end
