defmodule Grizzly.ZWave.CRCTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.CRC

  test "CRC16/AUG-CCITT" do
    assert 787 == CRC.crc16_aug_ccitt(<<0x01, 0x02, 0x03, 0x04>>)
  end
end
