defmodule Grizzly.ZWave.Commands.TimeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.TimeReport

  test "creates the command and validates params" do
    params = [rtc_failure?: false, hour: 12, minute: 10, second: 5]
    {:ok, _command} = TimeReport.new(params)
  end

  test "encodes params correctly" do
    params = [rtc_failure?: false, hour: 12, minute: 10, second: 5]
    {:ok, command} = TimeReport.new(params)
    expected_binary = <<0x00::size(1), 0x00::size(2), 0x0C::size(5), 0x0A, 0x05>>
    assert expected_binary == TimeReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00::size(1), 0x00::size(2), 0x0C::size(5), 0x0A, 0x05>>
    {:ok, params} = TimeReport.decode_params(params_binary)
    assert Keyword.get(params, :rtc_failure?) == false
    assert Keyword.get(params, :hour) == 12
    assert Keyword.get(params, :minute) == 10
    assert Keyword.get(params, :second) == 5
  end
end
