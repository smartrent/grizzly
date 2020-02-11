defmodule Grizzly.Test do
  use ExUnit.Case

  alias Grizzly.ZWave.Commands.SwitchBinaryReport

  describe "SwitchBinary Commands" do
    test "SwitchBinarySet version 1" do
      assert :ok == Grizzly.send_command(2, :switch_binary_set, target_value: :off)
    end

    test "SwitchBinarySet version 2" do
      assert :ok == Grizzly.send_command(2, :switch_binary_set, target_value: :on, duration: 100)
    end

    test "SWitchBinaryGet" do
      assert SwitchBinaryReport.new(target_value: :off) ==
               Grizzly.send_command(2, :switch_binary_get)
    end
  end

  test "handles nack responses" do
    assert {:error, :nack_response} == Grizzly.send_command(101, :switch_binary_get)
  end

  test "send a command to a node that hasn't been connected to yet" do
    assert SwitchBinaryReport.new(target_value: :off) ==
             Grizzly.send_command(50, :switch_binary_get)
  end
end
