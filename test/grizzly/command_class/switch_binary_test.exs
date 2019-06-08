defmodule Grizzly.CommandClass.SwitchBinary.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.SwitchBinary

  describe "encoding switch state" do
    test "on" do
      assert 0xFF == SwitchBinary.encode_switch_state(:on)
    end

    test "off" do
      assert 0x00 == SwitchBinary.encode_switch_state(:off)
    end
  end
end
