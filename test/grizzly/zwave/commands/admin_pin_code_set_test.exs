defmodule Grizzly.ZWave.Commands.AdminPinCodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AdminPinCodeSet

  test "encodes params correctly" do
    params = [code: "0123456789ABCDEF01234"]
    {:ok, command} = Commands.create(:admin_pin_code_set, params)

    assert AdminPinCodeSet.encode_params(command) ==
             <<0::4, 15::4, "0123456789ABCDE">>
  end

  test "decodes params correctly" do
    binary = <<0::4, 15::4, "0123456789ABCDE">>
    assert AdminPinCodeSet.decode_params(binary) == {:ok, [code: "0123456789ABCDE"]}
  end
end
