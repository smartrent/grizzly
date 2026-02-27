defmodule Grizzly.ZWave.Commands.AntitheftUnlockSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    magic_code = "hocuspocus"
    params = [magic_code: magic_code]
    {:ok, command} = Commands.create(:antitheft_unlock_set, params)
    expected_params_binary = <<0x7E, 0x03, 0x00::4, 0x0A::4>> <> magic_code
    assert expected_params_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    magic_code = "hocuspocus"
    params_binary = <<0x7E, 0x03, 0x00::4, 0x0A::4>> <> magic_code
    {:ok, command} = Grizzly.decode_command(params_binary)
    assert Keyword.get(command.params, :magic_code) == magic_code
  end
end
