defmodule Grizzly.ZWave.CommandClasses.SensorBinaryTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.CommandClasses.SensorBinary

  doctest Grizzly.ZWave.CommandClasses.SensorBinary, import: true

  describe "encode type" do
    test "when type is general purpose" do
      assert SensorBinary.encode_type(:general_purpose) == 0x01
    end

    test "when type is smoke" do
      assert SensorBinary.encode_type(:smoke) == 0x02
    end

    test "when type is c0" do
      assert SensorBinary.encode_type(:co) == 0x03
    end

    test "when type is c02" do
      assert SensorBinary.encode_type(:co2) == 0x04
    end

    test "when type is heat" do
      assert SensorBinary.encode_type(:heat) == 0x05
    end

    test "when type is water" do
      assert SensorBinary.encode_type(:water) == 0x06
    end

    test "when type is freeze" do
      assert SensorBinary.encode_type(:freeze) == 0x07
    end

    test "when type is tamper" do
      assert SensorBinary.encode_type(:tamper) == 0x08
    end

    test "when type is aux" do
      assert SensorBinary.encode_type(:aux) == 0x09
    end

    test "when type is door window" do
      assert SensorBinary.encode_type(:door_window) == 0x0A
    end

    test "when type is tilt" do
      assert SensorBinary.encode_type(:tilt) == 0x0B
    end

    test "when type is motion" do
      assert SensorBinary.encode_type(:motion) == 0x0C
    end

    test "when type is glass break" do
      assert SensorBinary.encode_type(:glass_break) == 0x0D
    end
  end

  describe "parse type" do
    test "when type is general purpose" do
      assert {:ok, :general_purpose} == SensorBinary.decode_type(0x01)
    end

    test "when type is smoke" do
      assert {:ok, :smoke} == SensorBinary.decode_type(0x02)
    end

    test "when type is c0" do
      assert {:ok, :co} == SensorBinary.decode_type(0x03)
    end

    test "when type is c02" do
      assert {:ok, :co2} == SensorBinary.decode_type(0x04)
    end

    test "when type is heat" do
      assert {:ok, :heat} == SensorBinary.decode_type(0x05)
    end

    test "when type is water" do
      assert {:ok, :water} == SensorBinary.decode_type(0x06)
    end

    test "when type is freeze" do
      assert {:ok, :freeze} == SensorBinary.decode_type(0x07)
    end

    test "when type is tamper" do
      assert {:ok, :tamper} == SensorBinary.decode_type(0x08)
    end

    test "when type is aux" do
      assert {:ok, :aux} == SensorBinary.decode_type(0x09)
    end

    test "when type is door window" do
      assert {:ok, :door_window} == SensorBinary.decode_type(0x0A)
    end

    test "when type is tilt" do
      assert {:ok, :tilt} == SensorBinary.decode_type(0x0B)
    end

    test "when type is motion" do
      assert {:ok, :motion} == SensorBinary.decode_type(0x0C)
    end

    test "when type is glass break" do
      assert {:ok, :glass_break} == SensorBinary.decode_type(0x0D)
    end
  end
end
