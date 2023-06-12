defmodule Grizzly.ZWave.Commands.MailboxQueueTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MailboxQueue

  test "encodes params correctly" do
    expected_binary = <<0::4, 1::1, 1::3, 2::8, 1::8, 2::8, 255::8>>

    {:ok, cmd} =
      MailboxQueue.new(
        last: true,
        operation: :pop,
        handle: 2,
        entry: <<0x01, 0x02, 0xFF>>
      )

    assert ^expected_binary = MailboxQueue.encode_params(cmd)

    expected_binary = <<0::4, 0::1, 4::3, 5::8, 0::8, 0::8, 0::8>>

    {:ok, cmd} =
      MailboxQueue.new(
        last: false,
        operation: :ack,
        handle: 5,
        entry: <<0x0, 0x0, 0x0>>
      )

    assert ^expected_binary = MailboxQueue.encode_params(cmd)
  end

  test "decodes params correctly" do
    {:ok, params} = MailboxQueue.decode_params(<<0::4, 1::1, 1::3, 2::8, 1::8, 2::8, 255::8>>)

    assert params[:last] == true
    assert params[:operation] == :pop
    assert params[:handle] == 2
    assert params[:entry] == <<0x01, 0x02, 0xFF>>

    {:ok, params} = MailboxQueue.decode_params(<<0::4, 0::1, 4::3, 5::8, 0::8, 0::8, 0::8>>)

    assert params[:last] == false
    assert params[:operation] == :ack
    assert params[:handle] == 5
    assert params[:entry] == <<0x0, 0x0, 0x0>>
  end
end
