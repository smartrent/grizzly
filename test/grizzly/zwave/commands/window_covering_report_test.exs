defmodule Grizzly.ZWave.Commands.WindowCoveringReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WindowCoveringReport

  test "creates the command and validates params" do
    params = [
      parameter_name: :out_left_positioned,
      current_value: 1,
      target_value: 10,
      duration: 5
    ]

    {:ok, _command} = WindowCoveringReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      parameter_name: :out_left_positioned,
      current_value: 1,
      target_value: 10,
      duration: 5
    ]

    {:ok, command} = WindowCoveringReport.new(params)
    expected_binary = <<1, 1, 10, 5>>
    assert expected_binary == WindowCoveringReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<1, 1, 10, 5>>
    {:ok, params} = WindowCoveringReport.decode_params(binary_params)
    assert Keyword.get(params, :parameter_name) == :out_left_positioned
    assert Keyword.get(params, :current_value) == 1
    assert Keyword.get(params, :target_value) == 10
    assert Keyword.get(params, :duration) == 5
  end
end
