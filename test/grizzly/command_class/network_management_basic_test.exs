defmodule Grizzly.CommandClass.NetworkManagementBasic.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NetworkManagementBasic

  describe "encoding" do
    test "encoding learn modes" do
      assert {:ok, 0x00} = NetworkManagementBasic.encode_learn_mode(:disable)
      assert {:ok, 0x01} = NetworkManagementBasic.encode_learn_mode(:enable)
      assert {:ok, 0x02} = NetworkManagementBasic.encode_learn_mode(:enable_routed)

      assert {:error, :invalid_arg, :fizzbuzz} ==
               NetworkManagementBasic.encode_learn_mode(:fizzbuzz)
    end
  end

  describe "decoding default statuses" do
    test "decoding done status" do
      assert :done == NetworkManagementBasic.decode_default_set_status(0x06)
    end

    test "decoding busy status" do
      assert :busy == NetworkManagementBasic.decode_default_set_status(0x07)
    end
  end

  describe "decoding DSK report" do
    test "decode full report when add mode is learn" do
      dsk = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>
      report_binary = <<0x00>> <> dsk

      expected_report = %{
        add_mode: :learn,
        dsk: "00258-00772-01286-01800-02314-02828-03342-03856"
      }

      assert expected_report == NetworkManagementBasic.decode_dsk_report(report_binary)
    end

    test "decode full report when add mode is add" do
      dsk = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>
      report_binary = <<0x01>> <> dsk

      expected_report = %{
        add_mode: :add,
        dsk: "00258-00772-01286-01800-02314-02828-03342-03856"
      }

      assert expected_report == NetworkManagementBasic.decode_dsk_report(report_binary)
    end

    test "decode add mode learn from byte" do
      byte = 0b1101_1100

      assert :learn == NetworkManagementBasic.add_mode_from_byte(byte)
    end

    test "decode add mode add from byte" do
      byte = 0b1101_1101

      assert :add == NetworkManagementBasic.add_mode_from_byte(byte)
    end
  end
end
