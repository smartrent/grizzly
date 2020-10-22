defmodule Grizzly.AssociationsTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Associations, Options}
  alias Grizzly.Associations.Association

  test "save association" do
    options = start_server(:save_test)
    assert Associations.save(:save_test, 1, [1, 2, 4]) == :ok

    File.rm!(options.associations_file)
  end

  test "get one missing association" do
    options = start_server(:get_one_nil)
    assert nil == Associations.get(:get_one_nil, 10)
    File.rm!(options.associations_file)
  end

  test "get all associations" do
    options = start_server(:get_all)
    :ok = Associations.save(:get_all, 1, [1, 2])
    assert [%Association{node_ids: [1, 2], grouping_id: 1}] == Associations.get_all(:get_all)

    File.rm!(options.associations_file)
  end

  test "delete all associations" do
    options = start_server(:delete_all)

    :ok = Associations.save(:delete_all, 1, [2, 3, 5])
    :ok = Associations.save(:delete_all, 2, [1, 2, 8])

    associations = Associations.get_all(:delete_all)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_all(:delete_all)

    assert Enum.empty?(Associations.get_all(:delete_all))
    File.rm!(options.associations_file)
  end

  test "delete all nodes from grouping" do
    options = start_server(:delete_all_from_grouping)

    :ok = Associations.save(:delete_all_from_grouping, 1, [2, 3, 5])
    :ok = Associations.save(:delete_all_from_grouping, 2, [1, 2, 8])

    associations = Associations.get_all(:delete_all_from_grouping)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_all_nodes_from_grouping(:delete_all_from_grouping, 1)

    assert nil == Associations.get(:delete_all_from_grouping, 1)

    # Ensure other groupings are effected
    assert %Association{grouping_id: 2} = Associations.get(:delete_all_from_grouping, 2)

    File.rm!(options.associations_file)
  end

  test "delete the nodes from the all groupings" do
    name = :delete_nodes_from_all_groupings
    options = start_server(name)

    :ok = Associations.save(name, 1, [1, 2, 3, 4])
    :ok = Associations.save(name, 2, [1, 2, 4])

    associations = Associations.get_all(name)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_nodes_from_all_groupings(name, [2, 3])

    # test if the nodes were removed form all groupings
    assert %Association{grouping_id: 1, node_ids: [1, 4]} = Associations.get(name, 1)
    assert %Association{grouping_id: 2, node_ids: [1, 4]} = Associations.get(name, 2)

    File.rm!(options.associations_file)
  end

  defp start_server(name) do
    options = make_options()

    {:ok, _pid} = Associations.start_link(options, name: name)

    options
  end

  defp make_options() do
    randfile_name = to_string(:rand.uniform())
    path = Path.join(System.tmp_dir!(), randfile_name)
    Options.new(associations_file: path)
  end
end
