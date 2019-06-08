defmodule Grizzly.Node.Test do
  use ExUnit.Case, async: true

  alias Grizzly.{Node, CommandClass}
  alias Grizzly.Conn.Config
  alias Grizzly.Node.Association
  alias Grizzly.Test.Client

  test "Create a new node" do
    zw_node = Node.new(id: 1, command_classes: [], security: :s0)

    assert zw_node == %Node{
             id: 1,
             command_classes: [],
             security: :s0,
             basic_cmd_class: nil,
             generic_cmd_class: nil,
             specific_cmd_class: nil,
             ip_address: nil,
             conn: nil,
             listening?: false
           }
  end

  test "makes a config correctly" do
    zw_node = %Node{ip_address: {1, 2, 3, 4, 5, 6, 7, 8}, id: 1}

    expectd_config = %Config{
      ip: {1, 2, 3, 4, 5, 6, 7, 8},
      port: 5000,
      client: Client
    }

    assert expectd_config == Node.make_config(zw_node)
  end

  test "connect to device" do
    zw_node = %Node{ip_address: {0, 0, 0, 0}, id: 1}

    {:ok, connected_node} = Node.connect(zw_node)

    assert connected_node.conn != nil
  end

  test "checks if the node has a particular command class" do
    zw_node = Node.new(id: 12, command_classes: [CommandClass.new(name: :foo, version: 1)])
    assert Node.has_command_class?(zw_node, :foo)
  end

  test "puts the association into the node's association list" do
    association = Association.new(0x01)

    associations =
      Node.new(id: 1) |> Node.put_association(association) |> Node.get_association_list()

    assert association in associations
  end
end
