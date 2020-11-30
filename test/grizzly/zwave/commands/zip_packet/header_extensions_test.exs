defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensionsTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions
  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.EncapsulationFormatInfo

  test "parses for expected delay" do
    header_ext = HeaderExtensions.from_binary(<<0x01, 0x03, 0x00, 0x00, 0x01>>)

    assert [{:expected_delay, 1}] == header_ext
  end

  test "parses for installation maintenance get" do
    header_ext = HeaderExtensions.from_binary(<<0x02, 0x00>>)
    assert [:installation_and_maintenance_get] == header_ext
  end

  test "parses for install maintenance report" do
    report_binary = <<0x03, 0x07, 0x01, 0x02, 0x00, 0x01, 0x00, 0x01, 0x00>>
    header_ext = HeaderExtensions.from_binary(report_binary)

    assert [
             {:installation_and_maintenance_report,
              [transmission_time: 1, route_changed: :not_changed]}
           ] == header_ext
  end

  test "parses encapsulation format info" do
    info_binary = <<0x84, 0x02, 0x80, 0x01>>
    header_ext = HeaderExtensions.from_binary(info_binary)
    encap_info = %EncapsulationFormatInfo{security_classes: [:s0], crc16: true}

    assert [{:encapsulation_format_info, encap_info}] == header_ext
  end

  test "makes the encapsulation format info into a binary" do
    encapinfo = EncapsulationFormatInfo.new(:non_secure, true)

    assert <<0x84, 0x02, 0x00, 0x01>> == EncapsulationFormatInfo.to_binary(encapinfo)
  end

  test "parse multicast addressing" do
    binary = <<0x05, 0x00>>
    expected_out = :multicast_addressing

    header_ext = HeaderExtensions.from_binary(binary)

    assert [expected_out] == header_ext
  end

  test "parse many extensions" do
    binary = <<0x05, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01, 0x03, 0x03, 0x04, 0x01, 0x15>>

    expected_out = [
      :multicast_addressing,
      {:expected_delay, 1},
      {:installation_and_maintenance_report, [ack_channel: 21]}
    ]

    assert expected_out == HeaderExtensions.from_binary(binary)
  end
end
