defmodule Grizzly.Packet.HeaderExtension.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet.HeaderExtension

  alias Grizzly.Packet.HeaderExtension.{
    ExpectedDelay,
    InstallationAndMaintenanceGet,
    InstallationAndMaintenanceReport,
    EncapsulationFormatInfo
  }

  test "parses for expected delay" do
    expected_delay = ExpectedDelay.new(1)
    header_ext = HeaderExtension.from_binary(<<0x01, 0x03, 0x00, 0x00, 0x01>>)

    assert [expected_delay] == header_ext
  end

  test "parses for installation maintenance get" do
    img = InstallationAndMaintenanceGet.new()
    header_ext = HeaderExtension.from_binary(<<0x02, 0x00>>)
    assert [img] == header_ext
  end

  test "parses for install maintenance report" do
    report_binary = <<0x03, 0x07, 0x01, 0x02, 0x00, 0x01, 0x00, 0x01, 0x00>>
    report = InstallationAndMaintenanceReport.from_binary(report_binary)

    header_ext = HeaderExtension.from_binary(report_binary)

    assert [report] == header_ext
  end

  test "parses encapsulation format info" do
    info_binary = <<0x84, 0x02, 0x80, 0x01>>
    info = EncapsulationFormatInfo.new(:s0, true)

    header_ext = HeaderExtension.from_binary(info_binary)

    assert [info] == header_ext
  end

  test "parse multicast addressing" do
    binary = <<0x05, 0x00>>
    expected_out = :multicast_addressing

    header_ext = HeaderExtension.from_binary(binary)

    assert [expected_out] == header_ext
  end

  test "parse many extensions" do
    binary = <<0x05, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01, 0x03, 0x03, 0x04, 0x01, 0x15>>

    expected_out = [
      :multicast_addressing,
      ExpectedDelay.new(1),
      InstallationAndMaintenanceReport.new([{:ack_channel, 0x015}])
    ]

    assert expected_out == HeaderExtension.from_binary(binary)
  end
end
