defmodule Grizzly.ZWave.SmartStart.MetaExtension.NetworkStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.SmartStart.MetaExtension.NetworkStatus

  describe "create a NetworkStatus.t()" do
    test "when network status is :not_in_network" do
      expected_network_status = %NetworkStatus{node_id: 0, network_status: :not_in_network}
      assert {:ok, expected_network_status} == NetworkStatus.new(0, :not_in_network)
    end

    test "when network status is :not_in_network and node id is greater than 0" do
      assert {:error, :invalid_node_id} == NetworkStatus.new(12, :not_in_network)
    end

    test "when network status is :included" do
      expected_network_status = %NetworkStatus{node_id: 5, network_status: :included}
      assert {:ok, expected_network_status} == NetworkStatus.new(5, :included)
    end

    test "when node id is 0 and network status is :included" do
      assert {:error, :invalid_node_id} == NetworkStatus.new(0, :included)
    end

    test "when network status is :failing" do
      expected_network_status = %NetworkStatus{node_id: 5, network_status: :failing}
      assert {:ok, expected_network_status} == NetworkStatus.new(5, :failing)
    end

    test "when node id is 0 and network status is :failing" do
      assert {:error, :invalid_node_id} == NetworkStatus.new(0, :failing)
    end

    test "when network status is invalid" do
      assert {:error, :invalid_network_status} == NetworkStatus.new(1, :sleeping)
    end
  end

  describe "encoding a NetworkStatus.t()" do
    test "when network status is :not_in_network" do
      {:ok, network_status} = NetworkStatus.new(0, :not_in_network)

      expected_binary = <<0x6E, 0x02, 0x00, 0x00>>

      assert {:ok, expected_binary} == NetworkStatus.to_binary(network_status)
    end

    test "when network status is :included" do
      {:ok, network_status} = NetworkStatus.new(4, :included)

      expected_binary = <<0x6E, 0x02, 0x04, 0x01>>

      assert {:ok, expected_binary} == NetworkStatus.to_binary(network_status)
    end

    test "when network status is :failing" do
      {:ok, network_status} = NetworkStatus.new(4, :failing)

      expected_binary = <<0x6E, 0x02, 0x04, 0x02>>

      assert {:ok, expected_binary} == NetworkStatus.to_binary(network_status)
    end
  end

  describe "decoding a NetworkStatus.t()" do
    test "when network status is :not_in_network" do
      binary = <<0x6E, 0x02, 0x00, 0x00>>

      {:ok, expected_network_status} = NetworkStatus.new(0, :not_in_network)

      assert {:ok, expected_network_status} == NetworkStatus.from_binary(binary)
    end

    test "when network status is :included" do
      binary = <<0x6E, 0x02, 0x06, 0x01>>

      {:ok, expected_network_status} = NetworkStatus.new(6, :included)

      assert {:ok, expected_network_status} == NetworkStatus.from_binary(binary)
    end

    test "when network status is :failing" do
      binary = <<0x6E, 0x02, 0x06, 0x02>>

      {:ok, expected_network_status} = NetworkStatus.new(6, :failing)

      assert {:ok, expected_network_status} == NetworkStatus.from_binary(binary)
    end

    test "when the critical bit is set" do
      binary = <<0x37::size(7), 1::size(1), 0x34, 0x01>>
      assert {:error, :critical_bit_set} == NetworkStatus.from_binary(binary)
    end
  end
end
