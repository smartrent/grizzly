defmodule Grizzly.ZWave.Commands.ClockSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ClockSet

  test "creates the command and validates params" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, _command} = ClockSet.new(params)
  end

  test "encodes params correctly" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, command} = ClockSet.new(params)
    expected_binary = <<0x01::3, 12::5, 30>>
    assert expected_binary == ClockSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01::3, 12::5, 30>>
    {:ok, params} = ClockSet.decode_params(binary_params)

    assert Keyword.get(params, :weekday) == :monday
    assert Keyword.get(params, :hour) == 12
    assert Keyword.get(params, :minute) == 30
  end
end
