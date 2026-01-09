defmodule Grizzly.ZWave.Commands.WindowCoveringSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.WindowCoveringSet

  test "creates the command and validates params" do
    params = [
      parameters: [
        [name: :out_left_positioned, value: 10],
        [name: :out_right_positioned, value: 30]
      ],
      duration: 5
    ]

    {:ok, _command} = Commands.create(:window_covering_set, params)
  end

  test "encodes params correctly" do
    params = [
      parameters: [
        [name: :out_left_positioned, value: 10],
        [name: :out_right_positioned, value: 30]
      ],
      duration: 5
    ]

    {:ok, command} = Commands.create(:window_covering_set, params)
    expected_binary = <<0x00::3, 0x02::5, 1, 10, 3, 30, 5>>
    assert expected_binary == WindowCoveringSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x02::5, 1, 10, 3, 30, 5>>
    {:ok, params} = WindowCoveringSet.decode_params(binary_params)
    parameters = Keyword.get(params, :parameters)

    parameter =
      Enum.find(parameters, fn list -> Keyword.fetch!(list, :name) == :out_left_positioned end)

    assert Keyword.fetch!(parameter, :value) == 10

    parameter =
      Enum.find(parameters, fn list -> Keyword.fetch!(list, :name) == :out_right_positioned end)

    assert Keyword.fetch!(parameter, :value) == 30
  end
end
