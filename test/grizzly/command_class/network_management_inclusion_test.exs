defmodule Grizzly.CommandClass.NetworkManagementInclusion.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NetworkManagementInclusion

  describe "encoding" do
    test "encoding add modes" do
      assert {:ok, 0x01} = NetworkManagementInclusion.encode_add_mode(:any)
      assert {:ok, 0x05} = NetworkManagementInclusion.encode_add_mode(:stop)
      assert {:ok, 0x07} = NetworkManagementInclusion.encode_add_mode(:any_s2)
      assert {:ok, 0x05} = NetworkManagementInclusion.encode_add_mode(0x05)

      assert {:error, :invalid_arg, :fizzbuzz} ==
               NetworkManagementInclusion.encode_add_mode(:fizzbuzz)
    end

    test "encoding remove modes" do
      assert {:ok, 0x01} = NetworkManagementInclusion.encode_remove_mode(:any)
      assert {:ok, 0x05} = NetworkManagementInclusion.encode_remove_mode(:stop)
      assert {:ok, 0x05} = NetworkManagementInclusion.encode_remove_mode(0x05)

      assert {:error, :invalid_arg, :any_s2} ==
               NetworkManagementInclusion.encode_remove_mode(:any_s2)
    end

    test "encoding accept" do
      assert {:ok, 0x01} = NetworkManagementInclusion.encode_accept(true)
      assert {:ok, 0x00} = NetworkManagementInclusion.encode_accept(false)

      assert {:error, :invalid_arg, :fizzbuzz} ==
               NetworkManagementInclusion.encode_accept(:fizzbuzz)
    end

    test "encoding csa" do
      assert {:ok, 0x02} = NetworkManagementInclusion.encode_csa(true)
      assert {:ok, 0x00} = NetworkManagementInclusion.encode_csa(false)

      assert {:error, :invalid_arg, :fizzbuzz} ==
               NetworkManagementInclusion.encode_csa(:fizzbuzz)
    end

    test "encoding accept s2 bootstrapping" do
      assert {:ok, 0x01} = NetworkManagementInclusion.encode_accept_s2_bootstrapping(true)
      assert {:ok, 0x00} = NetworkManagementInclusion.encode_accept_s2_bootstrapping(false)

      assert {:error, :invalid_arg, :fizzbuzz} ==
               NetworkManagementInclusion.encode_accept_s2_bootstrapping(:fizzbuzz)
    end
  end

  describe "decoding " do
    test "decoding neighbor update status" do
      assert :done == NetworkManagementInclusion.decode_node_neighbor_update_status(0x22)
    end
  end
end
