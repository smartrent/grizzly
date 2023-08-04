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
    assert 3 == Encoding.__float_bytes_needed__(32768)
    assert 2 == Encoding.__float_bytes_needed__(-32768)
    assert 3 == Encoding.__float_bytes_needed__(-32769)
  end
end
