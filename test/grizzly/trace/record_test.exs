defmodule Grizzly.Trace.RecordTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.{SwitchBinarySet, ZIPPacket}
  alias Grizzly.Trace.Record

  test "generate string log" do
    {:ok, encapsulated_command} = SwitchBinarySet.new(target_value: :on)
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(encapsulated_command, 0x01)
    binary = ZWave.to_binary(zip_packet)
    record = Record.new(binary, src: {{192, 168, 0, 1}, 0}, dest: {{192, 168, 0, 2}, 0})

    expected_string =
      "#{Time.to_string(record.timestamp)} 192.168.0.1 192.168.0.2 1   switch_binary_set <<255>>"

    assert expected_string == to_string(record)
  end

  test "decodes NodeAddDSKReport for S2 unauthenticated device without crashing" do
    trace = %Record{
      src: {{0xFD00, 0xBBBB, 0, 0, 0, 0, 0, 0x01}, 41230},
      dest: {{0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x02}, 41230},
      binary:
        <<35, 2, 0, 208, 42, 0, 0, 5, 132, 2, 4, 0, 52, 19, 123, 0, 110, 113, 215, 70, 212, 90,
          35, 31, 65, 21, 237, 23, 121, 95, 97, 122>>,
      timestamp: ~U[2023-01-01T21:11:41.766545Z]
    }

    expected_string =
      "21:11:41.766545 [fd00:bbbb::1]:41230 [fd00:aaaa::2]:41230 42  node_add_dsk_report <<123, 0, 110, 113, 215, 70, 212, 90, 35, 31, 65, 21, 237, 23, 121, 95, 97, 122>>"

    assert expected_string == to_string(trace)
  end

  test "encode NodeAddKeysSet without crashing" do
    trace = %Record{
      src: {{0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x02}, 41230},
      dest: {{0xFD00, 0xBBBB, 0, 0, 0, 0, 0, 0x01}, 41230},
      binary: <<35, 2, 128, 80, 127, 0, 0, 52, 18, 127, 1, 1>>,
      timestamp: ~U[2023-01-01T21:11:41.6732255Z]
    }

    to_string(trace)
  end

  test "pcap encoding" do
    record = %Record{
      src: {{0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x02}, 41230},
      dest: {{0xFD00, 0xBBBB, 0, 0, 0, 0, 0, 0x01}, 41230},
      binary: <<35, 2, 128, 80, 127, 0, 0, 52, 18, 127, 1, 1>>,
      timestamp: ~U[2023-01-01T21:11:41.6732255Z]
    }

    pcap_binary = Record.to_pcap(record)
    # 40 bytes for the ipv6 header
    expected_packet_size = byte_size(record.binary) + 40
    # and 16 bytes for the pcap header
    expected_pcap_binary_size = expected_packet_size + 16

    assert byte_size(pcap_binary) == expected_pcap_binary_size

    assert <<ts_sec::32, ts_usec::32, len::32, _::32, _ipv6_header::320, rest::binary>> =
             pcap_binary

    assert rest == record.binary
    assert ts_sec == DateTime.to_unix(record.timestamp)
    assert ts_sec * 1_000_000 + ts_usec == DateTime.to_unix(record.timestamp, :microsecond)
    assert len == expected_packet_size
  end
end
