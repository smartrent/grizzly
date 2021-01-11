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
end
