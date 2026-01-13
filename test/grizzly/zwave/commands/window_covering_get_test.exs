defmodule Grizzly.ZWave.Commands.WindowCoveringGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.WindowCoveringGet

  test "creates the command and validates params" do
    params = [parameter_name: :out_left_positioned]
    {:ok, _command} = Commands.create(:window_covering_get, params)
  end

  test "encodes params correctly" do
    params = [parameter_name: :out_left_positioned]
    {:ok, command} = Commands.create(:window_covering_get, params)
    expected_binary = <<1>>
    assert expected_binary == WindowCoveringGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<1>>
    {:ok, params} = WindowCoveringGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :parameter_name) == :out_left_positioned
  end
end
