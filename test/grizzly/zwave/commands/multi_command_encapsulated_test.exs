defmodule Grizzly.ZWave.Commands.MultiCommandEncapsulatedTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MultiCommandEncapsulated

  setup_all do
    {:ok, basic_set} = Grizzly.ZWave.Commands.BasicSet.new(value: :on)

    {:ok, switch_multilevel_set} =
      Grizzly.ZWave.Commands.SwitchMultilevelSet.new(target_value: 0x32, duration: 0x0A)

    commands = [
      basic_set,
      switch_multilevel_set
    ]

    {:ok, %{commands: commands}}
  end

  test "creates the command and validates params", %{commands: commands} do
    params = [commands: commands]
    {:ok, _command} = MultiCommandEncapsulated.new(params)
  end

  test "encodes params correctly", %{commands: commands} do
    params = [commands: commands]
    {:ok, command} = MultiCommandEncapsulated.new(params)
    basic_set_binary = <<0x03>> <> <<0x20, 0x01, 0xFF>>
    switch_multilevel_set_binary = <<0x04>> <> <<0x26, 0x01, 0x32, 0x0A>>
    expected_binary = <<0x02>> <> basic_set_binary <> switch_multilevel_set_binary
    assert expected_binary == MultiCommandEncapsulated.encode_params(command)
  end

  test "decodes params correctly", %{commands: commands} do
    basic_set_binary = <<0x03>> <> <<0x20, 0x01, 0xFF>>
    switch_multilevel_set_binary = <<0x04>> <> <<0x26, 0x01, 0x32, 0x0A>>
    params_binary = <<0x02>> <> basic_set_binary <> switch_multilevel_set_binary
    {:ok, params} = MultiCommandEncapsulated.decode_params(params_binary)

    assert Enum.sort(Keyword.get(params, :commands)) == Enum.sort(commands)
  end
end
