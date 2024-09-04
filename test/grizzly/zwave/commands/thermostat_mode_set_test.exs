defmodule Grizzly.ZWave.Commands.ThermostatModeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatModeSet

  test "creates the command and validates params" do
    params = [mode: :heat]
    {:ok, _command} = ThermostatModeSet.new(params)
  end

  test "encodes params correctly" do
    params = [mode: :heat]
    {:ok, command} = ThermostatModeSet.new(params)
    expected_binary = <<0x00::3, 0x01::5>>
    assert expected_binary == ThermostatModeSet.encode_params(command)

    assert_raise KeyError, fn ->
      params = [mode: :manufacturer_specific]
      {:ok, cmd} = ThermostatModeSet.new(params)
      ThermostatModeSet.encode_params(cmd)
    end

    assert_raise ArgumentError, fn ->
      params = [mode: :manufacturer_specific, manufacturer_data: "12345678"]
      {:ok, cmd} = ThermostatModeSet.new(params)
      ThermostatModeSet.encode_params(cmd)
    end

    params = [mode: :manufacturer_specific, manufacturer_data: "1234567"]
    {:ok, cmd} = ThermostatModeSet.new(params)
    assert <<0xFF, "1234567">> = ThermostatModeSet.encode_params(cmd)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x02::5>>
    {:ok, params} = ThermostatModeSet.decode_params(binary_params)
    assert Keyword.get(params, :mode) == :cool

    assert {:ok, params} = ThermostatModeSet.decode_params(<<0xFF, "1234567">>)
    assert params == [mode: :manufacturer_specific, manufacturer_data: "1234567"]
  end
end
