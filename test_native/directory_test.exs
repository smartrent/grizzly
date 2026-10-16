defmodule Grizzly.NativeDirectoryTest do
  use ExUnit.Case, async: true

  alias Exqlite.Sqlite3
  alias Grizzly.Backends.Zwrap.Directory
  alias Grizzly.Directory.Database

  defmodule Lease do
    def maintenance_acquire(owner) do
      send(owner, {:acquired, self()})
      {:ok, 42}
    end

    def maintenance_release(owner, token, reload) do
      send(owner, {:released, token, reload})
      :ok
    end
  end

  setup do
    nonce = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
    path = Path.join(System.tmp_dir!(), "grizzly-directory-#{nonce}.db")
    {:ok, db} = Sqlite3.open(path)

    :ok =
      Sqlite3.execute(db, """
      CREATE TABLE network(homeid INTEGER, nodeid INTEGER, version_major INTEGER, version_minor INTEGER);
      INSERT INTO network VALUES(123,7,1,0);
      CREATE TABLE nodes(nodeid INTEGER PRIMARY KEY, wakeUp_interval INTEGER, state INTEGER);
      INSERT INTO nodes VALUES(7,0,13),(256,120,13);
      CREATE TABLE endpoints(nodeid INTEGER,endpointid INTEGER);
      INSERT INTO endpoints VALUES(256,0),(256,1);
      """)

    Sqlite3.close(db)
    {:ok, directory} = Directory.start_link(name: nil, path: path, api: Lease, controller: self())
    Process.unlink(directory)

    on_exit(fn ->
      if Process.alive?(directory), do: GenServer.stop(directory)
      File.rm(path)
      File.rm(Directory.journal(path))
    end)

    %{path: path, directory: directory}
  end

  test "multi-row changes commit and reload; controller protection uses actual ID", %{
    directory: directory,
    path: path
  } do
    assert {:ok, :ok} = Directory.edit_node(256, %{wake_up_interval: 600}, directory)
    assert_receive {:acquired, _}
    assert_receive {:released, 42, true}
    refute File.exists?(Directory.journal(path))

    assert {:ok, %{"wakeUp_interval" => 600}} =
             Directory.transaction(
               directory,
               :read,
               &Database.select_one(&1, "SELECT wakeUp_interval FROM nodes WHERE nodeid=256")
             )

    assert_receive {:released, 42, false}
    assert {:error, :controller_record_protected} = Directory.remove_cache(7, directory)
    assert {:ok, :ok} = Directory.remove_cache(256, directory)

    assert {:ok, []} =
             Directory.transaction(
               directory,
               :read,
               &Database.select_all(&1, "SELECT * FROM endpoints WHERE nodeid=256")
             )
  end

  test "SQL failure rolls back every row and releases without reload", %{directory: directory} do
    assert {:error, :intentional} =
             Directory.transaction(directory, :write, fn db ->
               :ok = Sqlite3.execute(db, "UPDATE nodes SET wakeUp_interval=999")
               {:error, :intentional}
             end)

    assert_receive {:released, 42, false}

    assert {:ok, %{"wakeUp_interval" => 120}} =
             Directory.transaction(
               directory,
               :read,
               &Database.select_one(&1, "SELECT wakeUp_interval FROM nodes WHERE nodeid=256")
             )
  end

  test "read-only windows reject writes; interrupted journals fail closed", %{
    directory: directory,
    path: path
  } do
    assert {:error, _} =
             Directory.transaction(
               directory,
               :read,
               &Database.execute(&1, "DELETE FROM nodes", [])
             )

    File.write!(Directory.journal(path), "v1 committed\n")
    assert {:error, :recovery_required} = Directory.get_node(256, directory)
    assert {:error, :invalid_metadata} = Directory.edit_node(256, %{node_id: 2}, directory)
  end

  test "caller death cancels SQL owner without automatically resuming", %{
    directory: directory,
    path: path
  } do
    parent = self()

    caller =
      spawn(fn ->
        Directory.transaction(directory, :write, fn _db ->
          send(parent, {:inside_sql, self()})

          receive do
            :continue -> :ok
          end
        end)
      end)

    assert_receive {:inside_sql, worker}
    monitor = Process.monitor(worker)
    Process.exit(caller, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^worker, _}
    assert File.exists?(Directory.journal(path))
    refute_receive {:released, _, _}
    assert {:error, :recovery_required} = Directory.get_node(256, directory)
  end
end
