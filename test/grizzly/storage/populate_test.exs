defmodule Grizzly.Storage.PopulateTest do
  use ExUnit.Case, async: false

  alias Exqlite.Sqlite3
  alias Grizzly.Storage
  alias Grizzly.ZWave.DSK

  test "populates from a zipgateway database" do
    {:ok, fixture_db} = Sqlite3.open("test/fixtures/zipgateway.db")
    {:ok, db_contents} = Sqlite3.serialize(fixture_db, "main")
    {:ok, test_db} = Sqlite3.open(":memory:")
    :ok = Sqlite3.deserialize(test_db, "main", db_contents)
    :ok = Sqlite3.close(fixture_db)

    on_exit(fn ->
      Grizzly.Storage.delete_matches([])
      Sqlite3.close(test_db)
    end)

    start_supervised!({Storage.Populate, disabled: false, database: test_db})
    Process.sleep(100)

    assert Storage.get(["migrated_zipgateway_db"]) == true

    assert DSK.parse!("49251-58898-32906-38212-11636-23712-19238-51250") ==
             Storage.get_node_dsk(10)

    assert 4200 == Storage.get_node_wakeup_interval(16)
    assert %{listening?: true} = Storage.get_node_info(16)
    assert is_nil(Storage.get_node_wakeup_interval(9))
    assert is_nil(Storage.get_node_info(3))
  end
end
