defmodule Grizzly.Packet.HeaderExtension.BinaryParser.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet.HeaderExtension.BinaryParser

  test "create with a binary" do
    binary_parser = BinaryParser.from_binary(<<0x02, 0x03>>)

    assert <<0x02, 0x03>> == BinaryParser.to_binary(binary_parser)
  end

  test "parse next binary with a parser function" do
    bp = BinaryParser.from_binary(<<0x02, 0x03>>)

    {result, new_bp} =
      BinaryParser.next_with(bp, fn
        <<0x02, rest::binary>> -> {0x02, rest}
      end)

    assert result == 0x02

    assert <<0x03>> == BinaryParser.to_binary(new_bp)
  end

  test "parse binary into a list of parsed values" do
    binary = <<0x02, 0x03, 0x04, 0x05>>
    bp = BinaryParser.from_binary(binary)

    expected_return = [:two, :three_four, :five]

    return =
      BinaryParser.parse(bp, fn
        <<0x02, rest::binary>> -> {:two, rest}
        <<0x03, 0x04, rest::binary>> -> {:three_four, rest}
        <<0x05, rest::binary>> -> {:five, rest}
      end)

    assert expected_return == return
  end
end
