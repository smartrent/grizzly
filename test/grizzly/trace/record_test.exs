defmodule Grizzly.Trace.RecordTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.{SwitchBinarySet, ZIPPacket}
  alias Grizzly.Trace.Record

  test "generate string log" do
    {:ok, encapsulated_command} = SwitchBinarySet.new(target_value: :on)
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(encapsulated_command, 0x01)
    binary = ZWave.to_binary(zip_packet)
    record = Record.new(binary, src: :grizzly, dest: 1)

    expected_string = "   G -> 1   1    switch_binary_set <<37, 1, 255>>"

    assert Record.to_string(record) =~ expected_string
  end

  test "decodes NodeAddDSKReport for S2 unauthenticated device without crashing" do
    zip_packet_binary = <<35, 2, 0, 208, 42, 0, 0, 5, 132, 2, 4, 0>>

    command_binary =
      <<52, 19, 123, 0, 110, 113, 215, 70, 212, 90, 35, 31, 65, 21, 237, 23, 121, 95, 97, 122>>

    trace = %Grizzly.Trace.Record{
      src: 1,
      dest: :grizzly,
      binary: zip_packet_binary <> command_binary,
      timestamp: ~T[21:11:41.766545]
    }

    expected_string =
      "21:11:41.766   1 -> G   42   node_add_dsk_report #{inspect(command_binary)}"

    assert expected_string == Record.to_string(trace)
  end

  test "encode NodeAddKeysSet without crashing" do
    trace = %Grizzly.Trace.Record{
      src: :grizzly,
      dest: 1,
      binary: <<35, 2, 128, 80, 127, 0, 0, 52, 18, 127, 1, 1>>,
      timestamp: ~T[21:11:41.673225]
    }

    Record.to_string(trace)
  end
end
