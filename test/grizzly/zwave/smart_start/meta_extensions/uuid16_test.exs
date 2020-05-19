defmodule Grizzly.ZWave.SmartStart.MetaExtension.UUID16Test do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.SmartStart.MetaExtension.UUID16

  test "make a new uuid with hex format" do
    expected_uuid = %UUID16{format: :hex, uuid: "0102030405060708090A141516171819"}

    assert {:ok, expected_uuid} == UUID16.new(expected_uuid.uuid, :hex)
  end

  test "make a new uuid with ascii format" do
    expected_uuid = %UUID16{format: :ascii, uuid: "Hello Elixir!!!!"}

    assert {:ok, expected_uuid} == UUID16.new("Hello Elixir!!!!", :ascii)
  end

  test "make a new uuid with rfc format" do
    expected_uuid = %UUID16{format: :rfc4122, uuid: "58D5E212-165B-4CA0-909B-C86B9CEE0111"}

    assert {:ok, expected_uuid} == UUID16.new(expected_uuid.uuid, :rfc4122)
  end

  test "cannot create when hex uuid is too short" do
    assert {:error, :invalid_uuid_length} == UUID16.new("0123", :hex)
  end

  test "cannot create when hex uuid is too long" do
    assert {:error, :invalid_uuid_length} ==
             UUID16.new("0102030405060708090A1415161718190102030405060708090A141516171819", :hex)
  end

  test "cannot create when ascii uuid is too short" do
    assert {:error, :invalid_uuid_length} == UUID16.new("Hello!!!", :ascii)
  end

  test "cannot create when ascii uuid is too long" do
    assert {:error, :invalid_uuid_length} == UUID16.new("Hello Elixir!!!!!!!!!!!!", :ascii)
  end

  test "cannot create when rfc4122 is too long" do
    assert {:error, :invalid_uuid_length} ==
             UUID16.new("58D5E212-165B-4CA0-909B-C86B9CEE01111", :rfc4122)
  end

  test "cannot create when rfc4122 is too short" do
    assert {:error, :invalid_uuid_length} ==
             UUID16.new("58D5E212-165B-4CA0-09B-C86B9CEE0111", :rfc4122)
  end

  describe "from binary" do
    test "when critical bit is set" do
      binary = <<0x07, 0x11, 0x00, 0x00>>

      assert {:error, :critical_bit_set} == UUID16.from_binary(binary)
    end

    test "when representation is 32 hex numbers" do
      binary =
        <<0x06, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      expected_uuid = %UUID16{
        uuid: "0102030405060708090A141516171819",
        format: :hex
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is 16 ASCII characters" do
      binary =
        <<0x06, 0x11, 0x01, ?H, ?e, ?l, ?l, ?o, 0x20, ?E, ?l, ?i, ?x, ?i, ?r, ?!, ?!, ?!, ?!>>

      expected_uuid = %UUID16{
        uuid: "Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is sn: with 32 hex digits" do
      binary =
        <<0x06, 0x11, 0x02, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      expected_uuid = %UUID16{
        uuid: "sn:0102030405060708090A141516171819",
        format: :hex
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is sn: with with 16 ASCII characters" do
      binary =
        <<0x06, 0x11, 0x03, ?H, ?e, ?l, ?l, ?o, 0x20, ?E, ?l, ?i, ?x, ?i, ?r, ?!, ?!, ?!, ?!>>

      expected_uuid = %UUID16{
        uuid: "sn:Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is UUID: with 32 hex digits" do
      binary =
        <<0x06, 0x11, 0x04, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      expected_uuid = %UUID16{
        uuid: "UUID:0102030405060708090A141516171819",
        format: :hex
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is UUID: with 16 ASCII characters" do
      binary =
        <<0x06, 0x11, 0x05, ?H, ?e, ?l, ?l, ?o, 0x20, ?E, ?l, ?i, ?x, ?i, ?r, ?!, ?!, ?!, ?!>>

      expected_uuid = %UUID16{
        uuid: "UUID:Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "when representation is RFC 4122 UUID format" do
      binary =
        <<0x06, 0x11, 0x06, 0x58, 0xD5, 0xE2, 0x12, 0x16, 0x5B, 0x4C, 0xA0, 0x90, 0x9B, 0xC8,
          0x6B, 0x9C, 0xEE, 0x01, 0x11>>

      expected_uuid = %UUID16{
        uuid: "58D5E212-165B-4CA0-909B-C86B9CEE0111",
        format: :rfc4122
      }

      assert {:ok, expected_uuid} == UUID16.from_binary(binary)
    end

    test "Maps representation when format byte is between 7 and 99 back to 0 representation 0" do
      7..99
      |> Enum.map(fn representation ->
        <<0x06, 0x11, representation, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
          0x14, 0x15, 0x16, 0x17, 0x18, 0x19>>
      end)
      |> Enum.each(fn binary ->
        expected_uuid = %UUID16{
          uuid: "0102030405060708090A141516171819",
          format: :hex
        }

        assert {:ok, expected_uuid} == UUID16.from_binary(binary)
      end)
    end
  end

  describe "to binary" do
    test "when representation is 32 hex digits" do
      uuid16 = %UUID16{
        uuid: "0102030405060708090A141516171819",
        format: :hex
      }

      expected_binary =
        <<0x06, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      assert {:ok, expected_binary} == UUID16.to_binary(uuid16)
    end

    test "when representation is 32 hex digits with sn" do
      uuid16 = %UUID16{
        uuid: "sn:0102030405060708090A141516171819",
        format: :hex
      }

      expected_binary =
        <<0x06, 0x11, 0x02, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      assert {:ok, expected_binary} == UUID16.to_binary(uuid16)
    end

    test "when representation is 32 hex digits with UUID" do
      uuid16 = %UUID16{
        uuid: "UUID:0102030405060708090A141516171819",
        format: :hex
      }

      expected_binary =
        <<0x06, 0x11, 0x04, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      assert {:ok, expected_binary} == UUID16.to_binary(uuid16)
    end

    test "when representation is 16 ASCII characters" do
      uuid16 = %UUID16{
        uuid: "Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok,
              <<0x06, 0x011, 0x01, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x45, 0x6C, 0x69, 0x78,
                0x69, 0x72, 0x21, 0x21, 0x21, 0x21>>} == UUID16.to_binary(uuid16)
    end

    test "when representation is 16 ASCII characters wth sn" do
      uuid16 = %UUID16{
        uuid: "sn:Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok,
              <<0x06, 0x011, 0x03, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x45, 0x6C, 0x69, 0x78,
                0x69, 0x72, 0x21, 0x21, 0x21, 0x21>>} == UUID16.to_binary(uuid16)
    end

    test "when representation is 16 ASCII characters with UUID" do
      uuid16 = %UUID16{
        uuid: "UUID:Hello Elixir!!!!",
        format: :ascii
      }

      assert {:ok,
              <<0x06, 0x011, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x45, 0x6C, 0x69, 0x78,
                0x69, 0x72, 0x21, 0x21, 0x21, 0x21>>} == UUID16.to_binary(uuid16)
    end

    test "when representation is RFC 4122" do
      expected_binary =
        <<0x06, 0x11, 0x06, 0x58, 0xD5, 0xE2, 0x12, 0x16, 0x5B, 0x4C, 0xA0, 0x90, 0x9B, 0xC8,
          0x6B, 0x9C, 0xEE, 0x01, 0x11>>

      uuid = %UUID16{
        uuid: "58D5E212-165B-4CA0-909B-C86B9CEE0111",
        format: :rfc4122
      }

      assert {:ok, expected_binary} == UUID16.to_binary(uuid)
    end
  end
end
