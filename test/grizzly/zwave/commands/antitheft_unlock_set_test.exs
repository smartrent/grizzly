defmodule Grizzly.ZWave.Commands.AntitheftUnlockSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AntitheftUnlockSet

  test "creates the command and validates params" do
    params = [magic_code: "hocuspocus"]
    {:ok, _command} = AntitheftUnlockSet.new(params)
  end

  test "encodes params correctly" do
    magic_code = "hocuspocus"
    params = [magic_code: magic_code]
    {:ok, command} = AntitheftUnlockSet.new(params)
    expected_params_binary = <<0x00::size(4), 0x0A::size(4)>> <> magic_code
    assert expected_params_binary == AntitheftUnlockSet.encode_params(command)
  end

  test "decodes params correctly" do
    magic_code = "hocuspocus"
    params_binary = <<0x00::size(4), 0x0A::size(4)>> <> magic_code
    {:ok, params} = AntitheftUnlockSet.decode_params(params_binary)
    assert Keyword.get(params, :magic_code) == magic_code
  end
end
