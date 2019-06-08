defmodule Grizzly.CommandClass.DoorLock.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.DoorLock

  test "encoding bytes correctly" do
    assert 0x00 == DoorLock.encode_mode(:unsecured)
    assert 0xFF == DoorLock.encode_mode(:secured)
  end

  test "decode bytes correctly" do
    assert :secured == DoorLock.decode_mode(0xFF)
    assert :unsecured == DoorLock.decode_mode(0x00)
  end
end
