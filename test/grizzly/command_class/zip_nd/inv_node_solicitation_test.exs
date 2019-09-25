defmodule Grizzly.CommandClass.ZipNd.InvNodeSolicitation.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ZipNd.InvNodeSolicitation
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %InvNodeSolicitation{node_id: 2}} = InvNodeSolicitation.init(node_id: 2)
    end

    test "encodes correctly" do
      {:ok, command} = InvNodeSolicitation.init(node_id: 2)
      assert {:ok, <<0x58, 0x04, 0x00, 0x02>>} = InvNodeSolicitation.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = InvNodeSolicitation.init(node_id: :blue, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :node_id, :blue, InvNodeSolicitation})

      assert {:error, error} == InvNodeSolicitation.encode(command)
    end

    test "handle zip node advertisement response" do
      report = %{
        command_class: :zip_nd,
        command: :zip_node_advertisement,
        node_id: 0x02,
        ip_address: {0, 0, 0, 0}
      }

      {:ok, command} = InvNodeSolicitation.init(node_id: 0x02)
      packet = Packet.new(body: report)

      assert {:done, {:ok, {:node_ip, 0x02, {0, 0, 0, 0}}}} ==
               InvNodeSolicitation.handle_response(command, packet)
    end

    test "handle other responses" do
      {:ok, command} = InvNodeSolicitation.init([])

      assert {:continue, ^command} =
               InvNodeSolicitation.handle_response(command, %{command: :food})
    end
  end
end
