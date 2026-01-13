defmodule Grizzly.ZWave.Commands.ClockSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ClockSetReport

  test "creates the command and validates params" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, _command} = Commands.create(:clock_set, params)
  end

  test "encodes params correctly" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, command} = Commands.create(:clock_set, params)
    expected_binary = <<0x01::3, 12::5, 30>>
    assert expected_binary == ClockSetReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01::3, 12::5, 30>>
    {:ok, params} = ClockSetReport.decode_params(nil, binary_params)

    assert Keyword.get(params, :weekday) == :monday
    assert Keyword.get(params, :hour) == 12
    assert Keyword.get(params, :minute) == 30
  end
end
