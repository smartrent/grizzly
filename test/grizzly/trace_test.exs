defmodule Grizzly.TraceTest do
  use ExUnit.Case, async: true

  alias Grizzly.Trace
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, ZIPKeepAlive, ZIPPacket}

  setup %{test: test} = ctx do
    opts =
      ctx
      |> Map.take([:size, :record_keepalives])
      |> Map.put(:name, test)
      |> Enum.into([])

    pid = start_supervised!({Trace, opts})
    Map.put(ctx, :tracer, pid)
  end

  @tag size: 2
  test "log/3", %{tracer: tracer} do
    {:ok, cmd} = SwitchBinaryGet.new()

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, ZWave.to_binary(zip_packet), src: "src1", dest: "dest1")

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 3)
    Trace.log(tracer, ZWave.to_binary(zip_packet), src: "src2", dest: "dest2")

    list = Trace.list(tracer)
    assert length(list) == 2

    assert [
             %{binary: <<_::32, 2, _::binary>>, src: "src1", dest: "dest1"},
             %{binary: <<_::32, 3, _::binary>>, src: "src2", dest: "dest2"}
           ] = list
  end

  @tag size: 1
  test "resize/2", %{tracer: tracer} do
    {:ok, cmd} = SwitchBinaryGet.new()

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    list = Trace.list(tracer)
    assert length(list) == 1

    assert [%{binary: <<_::32, 2, _::binary>>}] = list

    Trace.resize(tracer, 3)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 3)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 4)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 5)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    list = Trace.list(tracer)
    assert length(list) == 3

    assert [
             %{binary: <<_::32, 3, _::binary>>},
             %{binary: <<_::32, 4, _::binary>>},
             %{binary: <<_::32, 5, _::binary>>}
           ] = list

    Trace.resize(tracer, 2)

    list = Trace.list(tracer)
    assert length(list) == 2

    assert [
             %{binary: <<_::32, 4, _::binary>>},
             %{binary: <<_::32, 5, _::binary>>}
           ] = list
  end

  test "clear/1", %{tracer: tracer} do
    {:ok, cmd} = SwitchBinaryGet.new()

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, ZWave.to_binary(zip_packet), [])

    list = Trace.list(tracer)
    assert length(list) == 2

    Trace.clear(tracer)

    list = Trace.list(tracer)
    assert list == []
  end

  test "records keepalives by default", %{tracer: tracer} do
    {:ok, keepalive} = ZIPKeepAlive.new(ack_flag: :ack_request)
    Trace.log(tracer, ZWave.to_binary(keepalive), [])

    {:ok, keepalive} = ZIPKeepAlive.new(ack_flag: :ack_response)
    Trace.log(tracer, ZWave.to_binary(keepalive), [])

    list = Trace.list(tracer)
    assert length(list) == 2

    assert [
             %{binary: <<0x23, 0x03, 0x80>>},
             %{binary: <<0x23, 0x03, 0x40>>}
           ] = list
  end

  @tag record_keepalives: false
  test "enable/disable keepalives", %{tracer: tracer} do
    {:ok, keepalive} = ZIPKeepAlive.new(ack_flag: :ack_request)
    Trace.log(tracer, ZWave.to_binary(keepalive), [])

    list = Trace.list(tracer)
    assert list == []

    Trace.record_keepalives(tracer, true)
    Trace.log(tracer, ZWave.to_binary(keepalive), [])

    Trace.record_keepalives(tracer, false)
    Trace.log(tracer, ZWave.to_binary(keepalive), [])

    list = Trace.list(tracer)
    assert [%{binary: <<0x23, 0x03, 0x80>>}] = list
  end
end
