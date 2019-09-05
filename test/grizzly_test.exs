defmodule Grizzly.Test do
  use ExUnit.Case

  alias Grizzly.Conn
  alias Grizzly.CommandClass.SwitchBinary.Set, as: SwitchBinarySet
  alias Grizzly.CommandClass.SwitchBinary.Get, as: SwitchBinaryGet
  alias Grizzly.CommandClass.NetworkManagementProxy.NodeListGet
  alias Grizzly.CommandClass.Battery.Get, as: BatteryGet
  alias Grizzly.CommandClass.ZipNd.InvNodeSolicitation
  alias Grizzly.CommandClass.ManufacturerSpecific.Get, as: ManufacturerSpecificGet
  alias Grizzly.Network.State, as: NetworkState
  alias Grizzly.Command.EncodeError

  setup do
    config = Grizzly.config()
    %Conn{} = conn = Conn.open(config)
    :ok = NetworkState.set(:idle)
    {:ok, %{conn: conn}}
  end

  describe "sending different types of command classes" do
    test "send application command class", %{conn: conn} do
      :ok = Grizzly.send_command(conn, SwitchBinarySet, seq_number: 0x08, value: :on)
    end

    test "send application command class that waits for a report", %{conn: conn} do
      {:ok, :on} = Grizzly.send_command(conn, SwitchBinaryGet, seq_number: 0x01)
    end

    test "send network command class", %{conn: conn} do
      {:ok, [1]} = Grizzly.send_command(conn, NodeListGet, seq_number: 0x01)
    end

    test "send management command class", %{conn: conn} do
      {:ok, 90} = Grizzly.send_command(conn, BatteryGet, seq_number: 0x01)
    end

    test "send raw command class", %{conn: conn} do
      {:ok, {:node_ip, 6, {64768, 48059, 0, 0, 0, 0, 0, 6}}} =
        Grizzly.send_command(conn, InvNodeSolicitation, node_id: 0x06)
    end

    test "send the manufacturer specific command", %{conn: conn} do
      {:ok, %{manufacturer_id: 335, product_id: 21558, product_type_id: 21570}} =
        Grizzly.send_command(conn, ManufacturerSpecificGet, seq_number: 0x01)
    end
  end

  describe "sending bad stuff to grizzly" do
    test "send values to switch binary set", %{conn: conn} do
      {:error, %EncodeError{}} =
        Grizzly.send_command(conn, SwitchBinarySet, seq_number: 0x08, value: :grizzly)
    end
  end
end
