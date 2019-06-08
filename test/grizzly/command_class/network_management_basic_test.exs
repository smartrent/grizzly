defmodule Grizzly.CommandClass.NetworkManagementBasic.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NetworkManagementBasic

  describe "decoding default statuses" do
    test "decoding done status" do
      assert :done == NetworkManagementBasic.decode_default_set_status(0x06)
    end

    test "decoding busy status" do
      assert :busy == NetworkManagementBasic.decode_default_set_status(0x07)
    end
  end
end
