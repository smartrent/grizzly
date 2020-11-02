defmodule Grizzly.ZWave.Commands.ClockReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ClockReport

  test "creates the command and validates params" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, _command} = ClockReport.new(params)
  end

  test "encodes params correctly" do
    params = [weekday: :monday, hour: 12, minute: 30]
    {:ok, command} = ClockReport.new(params)
    expected_binary = <<0x01::size(3), 12::size(5), 30>>
    assert expected_binary == ClockReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01::size(3), 12::size(5), 30>>
    {:ok, params} = ClockReport.decode_params(binary_params)

    assert Keyword.get(params, :weekday) == :monday
    assert Keyword.get(params, :hour) == 12
    assert Keyword.get(params, :minute) == 30
  end
end
