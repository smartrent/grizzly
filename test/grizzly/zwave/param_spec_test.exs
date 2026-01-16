defmodule Grizzly.ZWave.ParamSpecTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.ParamSpec

  doctest Grizzly.ZWave.ParamSpec

  describe "encode_value/2" do
    test "integer (signed and unsigned)" do
      spec = %ParamSpec{name: :foo, type: :int, size: 8}
      assert ParamSpec.encode_value(spec, 500) == <<0xF4>>

      spec = %ParamSpec{name: :foo, type: :uint, size: 8}
      assert ParamSpec.encode_value(spec, 500) == <<0xF4>>

      spec = %ParamSpec{name: :foo, type: :int, size: 16}
      assert ParamSpec.encode_value(spec, -300) == <<0xFE, 0xD4>>

      spec = %ParamSpec{name: :foo, type: :uint, size: 16}
      assert ParamSpec.encode_value(spec, -300) == <<0xFE, 0xD4>>

      spec = %ParamSpec{name: :foo, type: :uint, size: 16}
      assert ParamSpec.encode_value(spec, 65236) == <<0xFE, 0xD4>>
    end

    test "boolean" do
      spec = %ParamSpec{name: :foo, type: :boolean, size: 8}
      assert ParamSpec.encode_value(spec, true) == <<0xFF>>
      assert ParamSpec.encode_value(spec, false) == <<0x00>>

      spec = %ParamSpec{name: :foo, type: :boolean, size: 8, opts: [true: 1, false: 5]}
      assert ParamSpec.encode_value(spec, true) == <<0x01>>
      assert ParamSpec.encode_value(spec, false) == <<0x05>>
    end

    test "constant and reserved" do
      spec = %ParamSpec{name: :foo, type: :constant, size: 8, opts: [value: 0x42]}
      assert ParamSpec.encode_value(spec, :any_value) == <<0x42>>

      spec = %ParamSpec{name: :foo, type: :reserved, size: 8}
      assert ParamSpec.encode_value(spec, :any_value) == <<0x00>>
    end

    test "enum" do
      spec = %ParamSpec{
        name: :foo,
        type: :enum,
        size: 8,
        opts: [
          encode: fn
            :a -> 1
            :b -> 2
          end,
          decode: fn
            1 -> :a
            2 -> :b
          end
        ]
      }

      assert ParamSpec.encode_value(spec, :a) == <<0x01>>
      assert ParamSpec.encode_value(spec, :b) == <<0x02>>
    end
  end

  describe "decode_value/2" do
    test "integer (signed and unsigned)" do
      spec = %ParamSpec{name: :foo, type: :int, size: 8}
      assert ParamSpec.decode_value(spec, <<0xF4>>) == {:ok, -12}

      spec = %ParamSpec{name: :foo, type: :uint, size: 8}
      assert ParamSpec.decode_value(spec, <<0xF4>>) == {:ok, 244}

      spec = %ParamSpec{name: :foo, type: :int, size: 16}
      assert ParamSpec.decode_value(spec, <<0xFE, 0xD4>>) == {:ok, -300}

      spec = %ParamSpec{name: :foo, type: :uint, size: 16}
      assert ParamSpec.decode_value(spec, <<0xFE, 0xD4>>) == {:ok, 65236}
    end

    test "boolean" do
      spec = %ParamSpec{name: :foo, type: :boolean, size: 8}
      assert ParamSpec.decode_value(spec, <<0xFF>>) == {:ok, true}
      assert ParamSpec.decode_value(spec, <<0x00>>) == {:ok, false}

      spec = %ParamSpec{name: :foo, type: :boolean, size: 8, opts: [true: 1, false: 5]}
      assert ParamSpec.decode_value(spec, <<0x01>>) == {:ok, true}
      assert ParamSpec.decode_value(spec, <<0x05>>) == {:ok, true}
    end

    test "constant and reserved" do
      spec = %ParamSpec{name: :foo, type: :constant, size: 8, opts: [value: 0x42]}
      assert ParamSpec.decode_value(spec, <<0x42>>) == {:ok, 0x42}

      spec = %ParamSpec{name: :foo, type: :reserved, size: 8}
      assert ParamSpec.decode_value(spec, <<0x00>>) == {:ok, nil}
    end

    test "enum" do
      spec = %ParamSpec{
        name: :foo,
        type: :enum,
        size: 8,
        opts: [
          encode: fn
            :a -> 1
            :b -> 2
          end,
          decode: fn
            1 -> :a
            2 -> {:ok, :b}
          end
        ]
      }

      assert ParamSpec.decode_value(spec, <<0x01>>) == {:ok, :a}
      assert ParamSpec.decode_value(spec, <<0x02>>) == {:ok, :b}
    end

    test "error cases - wrong binary size" do
      spec = %ParamSpec{name: :foo, type: :int, size: 8}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :foo, value: <<0x01, 0x02>>}} =
               ParamSpec.decode_value(spec, <<0x01, 0x02>>)

      spec = %ParamSpec{name: :bar, type: :uint, size: 16}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :bar, value: <<0x01>>}} =
               ParamSpec.decode_value(spec, <<0x01>>)

      spec = %ParamSpec{name: :baz, type: :boolean, size: 8}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :baz, value: <<0x01, 0x02>>}} =
               ParamSpec.decode_value(spec, <<0x01, 0x02>>)
    end

    test "error cases - enum with wrong binary size" do
      spec = %ParamSpec{
        name: :test_enum,
        type: :enum,
        size: 8,
        opts: [
          encode: fn
            :a -> 1
            :b -> 2
          end,
          decode: fn
            1 -> :a
            2 -> :b
          end
        ]
      }

      assert {:error, %Grizzly.ZWave.DecodeError{param: :test_enum, value: <<0x01, 0x02>>}} =
               ParamSpec.decode_value(spec, <<0x01, 0x02>>)
    end

    test "error cases - enum decoder returns error" do
      spec = %ParamSpec{
        name: :test_enum,
        type: :enum,
        size: 8,
        opts: [
          encode: fn
            :a -> 1
            :b -> 2
          end,
          decode: fn
            1 -> :a
            2 -> :b
            v -> {:error, %Grizzly.ZWave.DecodeError{param: :test_enum, value: v}}
          end
        ]
      }

      assert {:error, %Grizzly.ZWave.DecodeError{param: :test_enum, value: 99}} =
               ParamSpec.decode_value(spec, <<99>>)

      # Also test when decoder returns generic error tuple
      spec = %ParamSpec{
        name: :other_enum,
        type: :enum,
        size: 8,
        opts: [
          encode: fn v -> v end,
          decode: fn
            1 -> :a
            v -> {:error, "Unknown value: #{v}"}
          end
        ]
      }

      assert {:error, %Grizzly.ZWave.DecodeError{param: :other_enum, value: 99}} =
               ParamSpec.decode_value(spec, <<99>>)
    end

    test "binary with fixed size" do
      spec = %ParamSpec{name: :data, type: :binary, size: 4}

      assert ParamSpec.decode_value(spec, <<0x01, 0x02, 0x03, 0x04>>) ==
               {:ok, <<0x01, 0x02, 0x03, 0x04>>}

      spec = %ParamSpec{name: :data, type: :binary, size: 2}
      assert ParamSpec.decode_value(spec, <<0xAB, 0xCD>>) == {:ok, <<0xAB, 0xCD>>}
    end

    test "binary with variable size" do
      spec = %ParamSpec{name: :data, type: :binary, size: :variable}
      assert ParamSpec.decode_value(spec, <<0x01, 0x02, 0x03>>) == {:ok, <<0x01, 0x02, 0x03>>}
      assert ParamSpec.decode_value(spec, <<>>) == {:ok, <<>>}
      assert ParamSpec.decode_value(spec, <<0xFF>>) == {:ok, <<0xFF>>}
    end

    test "binary with variable size based on length param" do
      spec = %ParamSpec{name: :data, type: :binary, size: {:variable, :data_length}}

      assert ParamSpec.decode_value(spec, <<0x01, 0x02, 0x03>>, data_length: 3) ==
               {:ok, <<0x01, 0x02, 0x03>>}

      assert ParamSpec.decode_value(spec, <<0xAA, 0xBB>>, data_length: 2) ==
               {:ok, <<0xAA, 0xBB>>}

      assert ParamSpec.decode_value(spec, <<0xFF>>, data_length: 1) == {:ok, <<0xFF>>}
    end

    test "length type - decodes as uint" do
      spec = %ParamSpec{name: :data_length, type: {:length, :data}, size: 8}
      assert ParamSpec.decode_value(spec, <<0x05>>) == {:ok, 5}

      spec = %ParamSpec{name: :data_length, type: {:length, :data}, size: 16}
      assert ParamSpec.decode_value(spec, <<0x01, 0x00>>) == {:ok, 256}
    end

    test "error cases - binary with wrong size" do
      spec = %ParamSpec{name: :data, type: :binary, size: 4}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :data, value: <<0x01, 0x02>>}} =
               ParamSpec.decode_value(spec, <<0x01, 0x02>>)

      assert {:error,
              %Grizzly.ZWave.DecodeError{param: :data, value: <<0x01, 0x02, 0x03, 0x04, 0x05>>}} =
               ParamSpec.decode_value(spec, <<0x01, 0x02, 0x03, 0x04, 0x05>>)
    end
  end

  describe "encode_value/3 with other_params" do
    test "length type - encodes the byte size of another parameter" do
      spec = %ParamSpec{name: :data_length, type: {:length, :data}, size: 8}
      assert ParamSpec.encode_value(spec, :ignored, data: <<0x01, 0x02, 0x03>>) == <<0x03>>

      spec = %ParamSpec{name: :data_length, type: {:length, :data}, size: 16}

      assert ParamSpec.encode_value(spec, :ignored, data: <<0xAA, 0xBB, 0xCC, 0xDD>>) ==
               <<0x00, 0x04>>
    end

    test "length type - encodes zero for empty binary" do
      spec = %ParamSpec{name: :data_length, type: {:length, :data}, size: 8}
      assert ParamSpec.encode_value(spec, :ignored, data: <<>>) == <<0x00>>
    end
  end

  describe "take_bits/3" do
    test "takes fixed number of bits" do
      spec = %ParamSpec{name: :foo, type: :uint, size: 8}
      assert ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>) == {:ok, {<<0x01>>, <<0x02, 0x03>>}}

      spec = %ParamSpec{name: :bar, type: :int, size: 16}
      assert ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>) == {:ok, {<<0x01, 0x02>>, <<0x03>>}}
    end

    test "takes binary type with fixed byte size" do
      spec = %ParamSpec{name: :data, type: :binary, size: 4}

      assert ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03, 0x04, 0x05>>) ==
               {:ok, {<<0x01, 0x02, 0x03, 0x04>>, <<0x05>>}}

      spec = %ParamSpec{name: :data, type: :binary, size: 2}

      assert ParamSpec.take_bits(spec, <<0xAA, 0xBB, 0xCC>>) ==
               {:ok, {<<0xAA, 0xBB>>, <<0xCC>>}}
    end

    test "takes all remaining bits for variable size" do
      spec = %ParamSpec{name: :data, type: :binary, size: :variable}

      assert ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>) ==
               {:ok, {<<0x01, 0x02, 0x03>>, <<>>}}

      assert ParamSpec.take_bits(spec, <<>>) == {:ok, {<<>>, <<>>}}
    end

    test "takes variable bits based on length parameter" do
      spec = %ParamSpec{name: :data, type: :binary, size: {:variable, :data_length}}

      assert ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03, 0x04>>, data_length: 2) ==
               {:ok, {<<0x01, 0x02>>, <<0x03, 0x04>>}}

      assert ParamSpec.take_bits(spec, <<0xAA, 0xBB, 0xCC>>, data_length: 3) ==
               {:ok, {<<0xAA, 0xBB, 0xCC>>, <<>>}}

      assert ParamSpec.take_bits(spec, <<0xFF, 0xEE>>, data_length: 1) ==
               {:ok, {<<0xFF>>, <<0xEE>>}}
    end

    test "error when not enough bits available" do
      spec = %ParamSpec{name: :foo, type: :uint, size: 16}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :foo, value: <<0x01>>, reason: reason}} =
               ParamSpec.take_bits(spec, <<0x01>>)

      assert reason == "not enough bits to decode parameter"

      # For non-binary types, need exactly enough bits
      spec = %ParamSpec{name: :bar, type: :int, size: 24}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :bar, value: <<0x01, 0x02>>, reason: _}} =
               ParamSpec.take_bits(spec, <<0x01, 0x02>>)

      # For binary types, need at least size bytes
      spec = %ParamSpec{name: :data, type: :binary, size: 5}

      assert {:error, %Grizzly.ZWave.DecodeError{param: :data, value: <<0x01, 0x02>>, reason: _}} =
               ParamSpec.take_bits(spec, <<0x01, 0x02>>)
    end

    test "error when variable length parameter is not provided" do
      spec = %ParamSpec{name: :data, type: :binary, size: {:variable, :missing_length}}

      assert_raise RuntimeError, fn ->
        ParamSpec.take_bits(spec, <<0x01, 0x02>>)
      end
    end
  end

  describe "num_bits/1" do
    test "returns bit size for integer types" do
      spec = %ParamSpec{name: :foo, type: :uint, size: 8}
      assert ParamSpec.num_bits(spec) == 8

      spec = %ParamSpec{name: :bar, type: :int, size: 16}
      assert ParamSpec.num_bits(spec) == 16

      spec = %ParamSpec{name: :baz, type: :boolean, size: 1}
      assert ParamSpec.num_bits(spec) == 1
    end

    test "returns bits for binary type (bytes * 8)" do
      spec = %ParamSpec{name: :data, type: :binary, size: 4}
      assert ParamSpec.num_bits(spec) == 32

      spec = %ParamSpec{name: :data, type: :binary, size: 1}
      assert ParamSpec.num_bits(spec) == 8
    end

    test "returns :variable for variable size" do
      spec = %ParamSpec{name: :data, type: :binary, size: :variable}
      assert ParamSpec.num_bits(spec) == :variable

      spec = %ParamSpec{name: :data, type: :binary, size: {:variable, :length}}
      assert ParamSpec.num_bits(spec) == :variable
    end
  end

  describe "include_when_decoding?/1" do
    test "includes regular parameters" do
      spec = %ParamSpec{name: :foo, type: :uint, size: 8}
      assert ParamSpec.include_when_decoding?(spec) == true

      spec = %ParamSpec{name: :bar, type: :binary, size: 4}
      assert ParamSpec.include_when_decoding?(spec) == true
    end

    test "excludes reserved parameters" do
      spec = %ParamSpec{name: :reserved, type: :reserved, size: 8}
      assert ParamSpec.include_when_decoding?(spec) == false
    end

    test "excludes hidden parameters" do
      spec = %ParamSpec{name: :hidden_field, type: :uint, size: 8, opts: [hidden: true]}
      assert ParamSpec.include_when_decoding?(spec) == false
    end

    test "includes parameters when hidden is explicitly false" do
      spec = %ParamSpec{name: :visible, type: :uint, size: 8, opts: [hidden: false]}
      assert ParamSpec.include_when_decoding?(spec) == true
    end
  end
end
