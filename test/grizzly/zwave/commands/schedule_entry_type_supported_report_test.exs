defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedReport

  test "creates the command and validates params" do
    params = [number_of_slots_week_day: 10, number_of_slots_year_day: 20]
    {:ok, _command} = ScheduleEntryTypeSupportedReport.new(params)
  end

  test "encodes params correctly" do
    params = [number_of_slots_week_day: 10, number_of_slots_year_day: 20]
    {:ok, command} = ScheduleEntryTypeSupportedReport.new(params)
    expected_binary = <<10, 20>>
    assert expected_binary == ScheduleEntryTypeSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<10, 20>>
    {:ok, expected_params} = ScheduleEntryTypeSupportedReport.decode_params(binary_params)
    assert Keyword.get(expected_params, :number_of_slots_week_day) == 10
    assert Keyword.get(expected_params, :number_of_slots_year_day) == 20
  end

  test "encodes v3 params correctly" do
    params = [
      number_of_slots_week_day: 10,
      number_of_slots_year_day: 20,
      number_of_slots_daily_repeating: 30
    ]

    {:ok, command} = ScheduleEntryTypeSupportedReport.new(params)
    expected_binary = <<10, 20, 30>>
    assert expected_binary == ScheduleEntryTypeSupportedReport.encode_params(command)
  end

  test "decodes v3 params correctly" do
    binary_params = <<10, 20, 30>>
    {:ok, expected_params} = ScheduleEntryTypeSupportedReport.decode_params(binary_params)
    assert Keyword.get(expected_params, :number_of_slots_week_day) == 10
    assert Keyword.get(expected_params, :number_of_slots_year_day) == 20
    assert Keyword.get(expected_params, :number_of_slots_daily_repeating) == 30
  end
end
