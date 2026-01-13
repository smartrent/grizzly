defmodule Grizzly.ZWave.Commands.TimeParametersSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.TimeParametersSetReport

  test "creates the command and validates params" do
    params = [year: 2020, month: 7, day: 17, hour_utc: 14, minute_utc: 30, second_utc: 45]
    {:ok, _command} = Commands.create(:time_parameters_set, params)
  end

  test "encodes params correctly" do
    params = [year: 2020, month: 7, day: 17, hour_utc: 14, minute_utc: 30, second_utc: 45]
    {:ok, command} = Commands.create(:time_parameters_set, params)
    expected_binary = <<2020::16, 7, 17, 14, 30, 45>>
    assert expected_binary == TimeParametersSetReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<2020::16, 7, 17, 14, 30, 45>>
    {:ok, params} = TimeParametersSetReport.decode_params(nil, params_binary)
    assert 2020 == Keyword.get(params, :year)
    assert 7 == Keyword.get(params, :month)
    assert 17 == Keyword.get(params, :day)
    assert 14 == Keyword.get(params, :hour_utc)
    assert 30 == Keyword.get(params, :minute_utc)
    assert 45 == Keyword.get(params, :second_utc)
  end
end
