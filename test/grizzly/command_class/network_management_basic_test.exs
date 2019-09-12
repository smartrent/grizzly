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
end
