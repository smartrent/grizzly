defmodule Grizzly.CommandClass.Version.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.Version

  describe "decoding library types" do
    test "static controller" do
      assert {:ok, :static_controller} == Version.decode_library_type(0x01)
    end

    test "controller" do
      assert {:ok, :controller} == Version.decode_library_type(0x02)
    end

    test "enhanced slave" do
      assert {:ok, :enhanced_slave} == Version.decode_library_type(0x03)
    end

    test "slave" do
      assert {:ok, :slave} == Version.decode_library_type(0x04)
    end

    test "installer" do
      assert {:ok, :installer} == Version.decode_library_type(0x05)
    end

    test "routing slave" do
      assert {:ok, :routing_slave} == Version.decode_library_type(0x06)
    end

    test "bridge controller" do
      assert {:ok, :bridge_controller} == Version.decode_library_type(0x07)
    end

    test "device under test" do
      assert {:ok, :device_under_test} == Version.decode_library_type(0x08)
    end

    test "av remote" do
      assert {:ok, :av_remote} == Version.decode_library_type(0x0A)
    end

    test "av device" do
      assert {:ok, :av_device} == Version.decode_library_type(0x0B)
    end

    test "invalid library type" do
      assert {:error, :invalid_library_type, 0xCC} == Version.decode_library_type(0xCC)
    end
  end

  test "decoding the version report" do
    report = %{
      protocol_library: :controller,
      protocol_version: 1,
      protocol_sub_version: 1,
      firmware_version: 1,
      firmware_sub_version: 1
    }

    assert {:ok, report} == Version.decode_version_report(<<0x02, 0x01, 0x01, 0x01, 0x01>>)
  end
end
