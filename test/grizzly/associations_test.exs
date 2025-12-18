defmodule Grizzly.AssociationsTest do
  use ExUnit.Case, async: true
  use Mimic.DSL

  alias Grizzly.Associations
  alias Grizzly.Associations.Association
  alias Grizzly.Options

  @moduletag max_per_group: 5

  setup :verify_on_exit!
  setup :set_mimic_private

  setup ctx do
    randfile_name = to_string(:rand.uniform())
    path = Path.join(System.tmp_dir!(), randfile_name)
    on_exit(fn -> File.rm(path) end)

    options =
      Options.new(associations_file: path, max_associations_per_group: ctx[:max_per_group])

    server = start_link_supervised!({Associations, [options, [name: ctx.test]]})

    %{server: server}
  end

  test "save association", %{server: server} do
    assert Associations.save(server, 1, [1, 2, 4]) == :ok
  end

  test "get non-existent group", %{server: server} do
    assert nil == Associations.get(server, 10)
  end

  test "get all associations", %{server: server} do
    :ok = Associations.save(server, 1, [1, 2, {3, 1}])

    assert [%Association{node_ids: [1, 2, {3, 1}], grouping_id: 1}] ==
             Associations.get_all(server)
  end

  @tag max_per_group: 2
  test "does not save more than max per group", %{server: server} do
    assert :ok = Associations.save(server, 1, [1, 2])
    assert :error = Associations.save(server, 1, [1, 2, 3])

    assert [%Association{node_ids: [1, 2], grouping_id: 1}] ==
             Associations.get_all(server)
  end

  test "delete all associations", %{server: server} do
    :ok = Associations.save(server, 1, [2, 3, 5])
    :ok = Associations.save(server, 2, [1, 2, 8])

    associations = Associations.get_all(server)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_all(server)

    assert Enum.empty?(Associations.get_all(server))
  end

  test "delete all nodes from grouping", %{server: server} do
    :ok = Associations.save(server, 1, [2, 3, 5])
    :ok = Associations.save(server, 2, [1, 2, 8])

    associations = Associations.get_all(server)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_all_nodes_from_grouping(server, 1)

    assert nil == Associations.get(server, 1)

    # Ensure other groupings are effected
    assert %Association{grouping_id: 2} = Associations.get(server, 2)
  end

  test "delete the nodes from the all groupings", %{server: server} do
    :ok = Associations.save(server, 1, [1, 2, 3, 4])
    :ok = Associations.save(server, 2, [1, 2, 4])

    associations = Associations.get_all(server)

    # check to ensure saved worked
    assert Enum.find_value(associations, &(&1.grouping_id == 1))
    assert Enum.find_value(associations, &(&1.grouping_id == 2))

    :ok = Associations.delete_nodes_from_all_groupings(server, [2, 3])

    # test if the nodes were removed form all groupings
    assert %Association{grouping_id: 1, node_ids: [1, 4]} = Associations.get(server, 1)
    assert %Association{grouping_id: 2, node_ids: [1, 4]} = Associations.get(server, 2)
  end

  test "z-wave reset notifies lifeline association group", %{server: server} do
    assert :ok = Associations.save(server, 1, [2, 3, 4])

    expect Grizzly.send_command(2, :device_reset_locally_notification), do: :ok
    expect Grizzly.send_command(3, :device_reset_locally_notification), do: :ok
    expect Grizzly.send_command(4, :device_reset_locally_notification), do: :ok

    expect Grizzly.send_command(:gateway, :default_set, _, _),
      do: {:ok, %Grizzly.Report{node_id: 1, type: :command, status: :complete}}

    _ = Grizzly.Network.reset_controller(associations_server: server)
  end

  test "z-wave reset deletes all associations", %{server: server} do
    assert :ok = Associations.save(server, 1, [1, 2, 3, 4])
    assert :ok = Associations.save(server, 2, [1, 2, 4])

    expect Grizzly.send_command(:gateway, :default_set, _, _),
      do: {:ok, %Grizzly.Report{node_id: 1, type: :command, status: :complete}}

    _ = Grizzly.Network.reset_controller(notify: false, associations_server: server)

    assert [] == Associations.get_all(server)
  end
end
