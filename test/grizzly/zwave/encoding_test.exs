defmodule Grizzly.ZWave.EncodingTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Encoding
  doctest Grizzly.ZWave.Encoding, import: true

  test "__float_bits_needed__/1" do
    assert 8 == Encoding.__float_bits_needed__(127)
    assert 9 == Encoding.__float_bits_needed__(128)
    assert 8 == Encoding.__float_bits_needed__(-128)
    assert 9 == Encoding.__float_bits_needed__(-129)

    assert 16 == Encoding.__float_bits_needed__(32767)
    assert 17 == Encoding.__float_bits_needed__(32768)
    assert 16 == Encoding.__float_bits_needed__(-32768)
    assert 17 == Encoding.__float_bits_needed__(-32769)
  end

  test "__float_bytes_needed__/1" do
    assert 1 == Encoding.__float_bytes_needed__(0)
    assert 1 == Encoding.__float_bytes_needed__(1)
    assert 1 == Encoding.__float_bytes_needed__(-1)
    assert 1 == Encoding.__float_bytes_needed__(127)
    assert 2 == Encoding.__float_bytes_needed__(128)
    assert 1 == Encoding.__float_bytes_needed__(-128)
    assert 2 == Encoding.__float_bytes_needed__(-129)

    assert 2 == Encoding.__float_bytes_needed__(32767)
    assert 4 == Encoding.__float_bytes_needed__(32768)
    assert 2 == Encoding.__float_bytes_needed__(-32768)
    assert 4 == Encoding.__float_bytes_needed__(-32769)
  end

  test "__float_precision__/1" do
    assert 0 == Encoding.__float_precision__(0)
    assert 2 == Encoding.__float_precision__(1.27)
    assert 3 == Encoding.__float_precision__(1.273)
    assert 7 == Encoding.__float_precision__(1.27341234124)

    assert_raise ArgumentError, fn ->
      Encoding.__float_precision__(4_235_573_285.134538135132)
    end
  end
end
