defmodule Grizzly.ZWave.Commands.WindowCoveringStopLevelChangeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WindowCoveringStopLevelChange

  test "creates the command and validates params" do
    params = [parameter_name: :out_left_positioned]
    {:ok, _command} = WindowCoveringStopLevelChange.new(params)
  end

  test "encodes params correctly" do
    params = [parameter_name: :out_left_positioned]
    {:ok, command} = WindowCoveringStopLevelChange.new(params)
    expected_binary = <<1>>
    assert expected_binary == WindowCoveringStopLevelChange.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<1>>
    {:ok, params} = WindowCoveringStopLevelChange.decode_params(binary_params)
    assert Keyword.get(params, :parameter_name) == :out_left_positioned
  end
end
