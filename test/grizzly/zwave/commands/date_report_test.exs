defmodule Grizzly.ZWave.Commands.DateReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.DateReport

  test "creates the command and validates params" do
    params = [year: 2020, month: 7, day: 16]
    {:ok, _command} = Commands.create(:date_report, params)
  end

  test "encodes params correctly" do
    params = [year: 2020, month: 7, day: 16]
    {:ok, command} = Commands.create(:date_report, params)
    expected_binary = <<2020::16, 7, 16>>
    assert expected_binary == DateReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<2020::16, 7, 16>>
    {:ok, params} = DateReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :year) == 2020
    assert Keyword.get(params, :month) == 7
    assert Keyword.get(params, :day) == 16
  end
end
