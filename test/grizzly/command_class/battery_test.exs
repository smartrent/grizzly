defmodule Grizzly.CommandClass.Battery.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.Battery

  describe "decoding battery levels" do
    test "when battery level is a low warning" do
      assert :low_battery_warning == Battery.decode_level(0xFF)
    end

    test "basic decoding" do
      assert 100 == Battery.decode_level(0x64)
    end
  end
end
