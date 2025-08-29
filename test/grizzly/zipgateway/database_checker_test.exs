defmodule Grizzly.ZIPGateway.DatabaseCheckerTest do
  use ExUnit.Case, async: true

  alias Exqlite.Sqlite3
  alias Grizzly.ZIPGateway.Database, as: ZIPGatewayDb
  alias Grizzly.ZIPGateway.DatabaseChecker

  # Nodes of interest in the test database:

  # * Node 30: this node exhibits the behavior where `Grizzly.Node.get_info/2` returns
  #   a completely empty command class list. This happens because there are no records
  #   in the endpoints table for this node. As above, this state can be recovered by
  #   deleting the node.

  setup do
    # Copy the sample database into an in-memory database for testing
    {:ok, fixture_db} = Sqlite3.open("test/fixtures/zipgateway.db")
    {:ok, db_contents} = Sqlite3.serialize(fixture_db, "main")
    {:ok, test_db} = Sqlite3.open(":memory:")
    :ok = Sqlite3.deserialize(test_db, "main", db_contents)
    Sqlite3.close(fixture_db)

    on_exit(fn -> Sqlite3.close(test_db) end)

    {:ok, db: test_db}
  end

  test "Only expected nodes are deleted", %{db: db} do
    # Double check that the node exists in the db
    assert {:ok, %{id: 20}} = ZIPGatewayDb.get_node(db, 20)

    assert :ignore = DatabaseChecker.start_link(database_file: db)

    assert {:ok, nil} = ZIPGatewayDb.get_node(db, 20)

    assert {:ok, nodes} = ZIPGatewayDb.select_all(db, "SELECT * FROM nodes")
    assert length(nodes) == 10
  end
end
