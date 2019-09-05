defmodule Grizzly.CommandClass.SwitchBinary.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.SwitchBinary

  describe "encoding switch state" do
    test "on" do
      assert {:ok, 0xFF} == SwitchBinary.encode_switch_state(:on)
    end

    test "off" do
      assert {:ok, 0x00} == SwitchBinary.encode_switch_state(:off)
    end

    test "nil" do
      assert {:error, :invalid_arg, nil} == SwitchBinary.encode_switch_state(nil)
    end

    test "number 1" do
      assert {:error, :invalid_arg, 1} == SwitchBinary.encode_switch_state(1)
    end

    test "string grizzly" do
      assert {:error, :invalid_arg, "grizzly"} == SwitchBinary.encode_switch_state("grizzly")
    end

    test "atom grizzly" do
      assert {:error, :invalid_arg, :grizzly} == SwitchBinary.encode_switch_state(:grizzly)
    end
  end
end
