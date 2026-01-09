defmodule Grizzly.TraceTest do
  use ExUnit.Case, async: true

  alias Grizzly.Trace
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ZIPPacket

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
    {:ok, cmd} = Commands.create(:switch_binary_get)

    # The sleeps are to ensure records get different timestamps
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, :grizzly, 5, ZWave.to_binary(zip_packet))
    Process.sleep(10)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, 6, :grizzly, ZWave.to_binary(zip_packet))
    Process.sleep(10)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 3)
    Trace.log(tracer, 5, :grizzly, ZWave.to_binary(zip_packet))
    Process.sleep(10)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 4)
    Trace.log(tracer, :grizzly, 5, ZWave.to_binary(zip_packet))
    Process.sleep(10)

    list = Trace.list(tracer)
    assert length(list) == 3

    assert [
             %{binary: <<_::32, 2, _::binary>>, src: 6, dest: :grizzly},
             %{binary: <<_::32, 3, _::binary>>, src: 5, dest: :grizzly},
             %{binary: <<_::32, 4, _::binary>>, src: :grizzly, dest: 5}
           ] = list

    list = Trace.list(tracer, node_id: 5)
    assert length(list) == 2

    assert [
             %{binary: <<_::32, 3, _::binary>>, src: 5, dest: :grizzly},
             %{binary: <<_::32, 4, _::binary>>, src: :grizzly, dest: 5}
           ] = list
  end

  @tag size: 1
  test "resize/2", %{tracer: tracer} do
    {:ok, cmd} = Commands.create(:switch_binary_get)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, :grizzly, 4, ZWave.to_binary(zip_packet))

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, :grizzly, 4, ZWave.to_binary(zip_packet))

    list = Trace.list(tracer)
    assert length(list) == 1

    assert [%{binary: <<_::32, 2, _::binary>>}] = list

    Trace.resize(tracer, 3)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 3)
    Trace.log(tracer, :grizzly, 4, ZWave.to_binary(zip_packet))

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 4)
    Trace.log(tracer, :grizzly, 4, ZWave.to_binary(zip_packet))

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 5)
    Trace.log(tracer, :grizzly, 4, ZWave.to_binary(zip_packet))

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
    {:ok, cmd} = Commands.create(:switch_binary_get)

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 1)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(zip_packet))

    {:ok, zip_packet} = ZIPPacket.with_zwave_command(cmd, 2)
    Trace.log(tracer, :grizzly, 2, ZWave.to_binary(zip_packet))

    list = Trace.list(tracer)
    assert length(list) == 2

    Trace.clear(tracer)

    list = Trace.list(tracer)
    assert list == []
  end

  test "records keepalives by default", %{tracer: tracer} do
    {:ok, keepalive} = Commands.create(:keep_alive, ack_flag: :ack_request)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(keepalive))

    {:ok, keepalive} = Commands.create(:keep_alive, ack_flag: :ack_response)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(keepalive))

    list = Trace.list(tracer)
    assert length(list) == 2

    assert [
             %{binary: <<0x23, 0x03, 0x80>>},
             %{binary: <<0x23, 0x03, 0x40>>}
           ] = list
  end

  @tag record_keepalives: false
  test "enable/disable keepalives", %{tracer: tracer} do
    {:ok, keepalive} = Commands.create(:keep_alive, ack_flag: :ack_request)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(keepalive))

    list = Trace.list(tracer)
    assert list == []

    Trace.record_keepalives(tracer, true)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(keepalive))

    Trace.record_keepalives(tracer, false)
    Trace.log(tracer, :grizzly, 1, ZWave.to_binary(keepalive))

    list = Trace.list(tracer)
    assert [%{binary: <<0x23, 0x03, 0x80>>}] = list
  end
end
