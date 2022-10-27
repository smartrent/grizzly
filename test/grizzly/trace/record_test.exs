defmodule Grizzly.Trace.RecordTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.{SwitchBinarySet, ZIPPacket}
  alias Grizzly.Trace.Record

  test "generate string log" do
    {:ok, encapsulated_command} = SwitchBinarySet.new(target_value: :on)
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(encapsulated_command, 0x01)
    binary = ZWave.to_binary(zip_packet)
    record = Record.new(binary, src: "192.168.0.1", dest: "192.168.0.2")

    expected_string =
      "#{Time.to_string(record.timestamp)} #{record.src} #{record.dest} 1   switch_binary_set <<255>>"

    assert expected_string == Record.to_string(record)
  end

  test "decodes NodeAddDSKReport for S2 unauthenticated device without crashing" do
    trace = %Grizzly.Trace.Record{
      src: "[fd00:bbbb::1]:41230",
      dest: "[fd00:aaaa::2]:41230",
      binary:
        <<35, 2, 0, 208, 42, 0, 0, 5, 132, 2, 4, 0, 52, 19, 123, 0, 110, 113, 215, 70, 212, 90,
          35, 31, 65, 21, 237, 23, 121, 95, 97, 122>>,
      timestamp: ~T[21:11:41.766545]
    }

    expected_string =
      "21:11:41.766545 [fd00:bbbb::1]:41230 [fd00:aaaa::2]:41230 42  node_add_dsk_report <<123, 0, 110, 113, 215, 70, 212, 90, 35, 31, 65, 21, 237, 23, 121, 95, 97, 122>>"

    assert expected_string == Record.to_string(trace)
  end

  test "encode NodeAddKeysSet without crashing" do
    trace = %Grizzly.Trace.Record{
      src: "[fd00:aaaa::2]:41230",
      dest: "[fd00:bbbb::1]:41230",
      binary: <<35, 2, 128, 80, 127, 0, 0, 52, 18, 127, 1, 1>>,
      timestamp: ~T[21:11:41.673225]
    }

    Record.to_string(trace)
  end
end
