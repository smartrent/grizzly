defmodule Grizzly.ZWave.Commands.AntitheftUnlockSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AntitheftUnlockSet

  test "creates the command and validates params" do
    params = [magic_code: "hocuspocus"]
    {:ok, _command} = Commands.create(:antitheft_unlock_set, params)
  end

  test "encodes params correctly" do
    magic_code = "hocuspocus"
    params = [magic_code: magic_code]
    {:ok, command} = Commands.create(:antitheft_unlock_set, params)
    expected_params_binary = <<0x00::4, 0x0A::4>> <> magic_code
    assert expected_params_binary == AntitheftUnlockSet.encode_params(command)
  end

  test "decodes params correctly" do
    magic_code = "hocuspocus"
    params_binary = <<0x00::4, 0x0A::4>> <> magic_code
    {:ok, params} = AntitheftUnlockSet.decode_params(params_binary)
    assert Keyword.get(params, :magic_code) == magic_code
  end
end
