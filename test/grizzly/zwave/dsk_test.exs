defmodule Grizzly.ZWave.DSKTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.DSK
  doctest DSK

  @dsk_string "33654-49908-42539-00289-58381-21884-63570-22247"
  @dsk_binary <<33654::16, 49908::16, 42539::16, 00289::16, 58381::16, 21884::16, 63570::16,
                22247::16>>
  @dsk_struct %DSK{raw: @dsk_binary}

  test "new/1" do
  end

  test "parse/1" do
    assert {:ok, @dsk_struct} == DSK.parse(@dsk_string)
    assert {:ok, @dsk_struct} == DSK.parse(String.replace(@dsk_string, "-", " "))
    assert {:ok, @dsk_struct} == DSK.parse(String.replace(@dsk_string, "-", ""))

    assert {:ok, %DSK{raw: <<12345::16>>}} == DSK.parse("12345")
    assert {:ok, %DSK{raw: <<0::16>>}} == DSK.parse("00000")

    assert {:error, :invalid_dsk} == DSK.parse(@dsk_string <> "12345")
    assert {:error, :invalid_dsk} == DSK.parse("")
    assert {:error, :invalid_dsk} == DSK.parse("70000")
    assert {:error, :invalid_dsk} == DSK.parse("12ABC")
    assert {:error, :invalid_dsk} == DSK.parse("1234")
    assert {:error, :invalid_dsk} == DSK.parse("123")
    assert {:error, :invalid_dsk} == DSK.parse("12")
    assert {:error, :invalid_dsk} == DSK.parse("1")
  end

  test "to_string/1" do
    assert DSK.to_string(@dsk_struct) == @dsk_string
  end

  test "inspecting a DSK" do
    assert inspect(@dsk_struct) == "#DSK<" <> @dsk_string <> ">"
  end
end
