defmodule Grizzly.ZIPGateway.Database do
  @moduledoc """
  Functions for inspecting and debugging Z/IP Gateway's SQLite database.
  """

  alias Exqlite.Sqlite3
  alias Grizzly.ZWave.{CommandClasses, DeviceClasses}
  alias Grizzly.ZWave.DSK

  import Bitwise

  @type query_result(result) :: {:ok, result} | {:error, Sqlite3.reason()}

  @type security_flag ::
          {:s0 | :s2_unauthenticated | :s2_authenticated | :s2_access_control | :known_bad,
           boolean()}
  @type probe_state() :: :ok | :never_started | :probe_started | :probe_failed
  @type node_state() ::
          :created
          | :probe_node_info
          | :probe_product_id
          | :enumerate_endpoints
          | :find_endpoints
          | :check_wakeup_cc_version
          | :get_wakeup_capabilities
          | :set_wakeup_interval
          | :assign_return_route
          | :probe_wakeup_interval
          | :probe_endpoints
          | :mdns_probe
          | :mdns_endpoint_probe
          | :done
          | :probe_fail
          | :failing

  @type node_mode ::
          :not_probed
          | :nonlistening
          | :always_listening
          | :flirs
          | :wakeup
          | :wakeup_firmware_upgrade

  @type mode_flag ::
          {:mode, node_mode() | :unknown} | {:deleted | :failed | :low_battery, boolean()}

  @type properties_flag ::
          {:portable, boolean()} | {:just_added, String.t()} | {:added_by, String.t()}

  @type version_capability ::
          :version_get | :version_command_class_get | :version_zwave_software_get

  @type zwave_node :: %{
          id: Grizzly.zwave_node_id(),
          dsk: Grizzly.ZWave.DSK.t() | nil,
          last_awake: pos_integer(),
          last_update: pos_integer(),
          manufacturer_id: 0..0xFFFF,
          product_type: 0..0xFFFF,
          product_id: 0..0xFFFF,
          mode: [mode_flag()],
          security_flags: [security_flag()],
          properties_flags: [properties_flag()],
          probe_state: probe_state(),
          state: node_state(),
          version_capabilities: [{version_capability(), boolean()}],
          basic_device_class: DeviceClasses.basic_device_class() | nil,
          wake_up_interval: non_neg_integer() | nil
        }

  @type endpoint :: %{
          id: non_neg_integer(),
          node_id: Grizzly.zwave_node_id(),
          generic_device_class: DeviceClasses.generic_device_class() | nil,
          specific_device_class: DeviceClasses.specific_device_class() | nil,
          command_classes: CommandClasses.command_class_list()
        }

  @doc """
  Opens a SQLite database and passes the connection handle to the given function,
  then closes the database on completion.

  If the first argument is a reference to an already-open SQLite database, the
  first and last steps will be skipped. This is mostly useful for testing.

  If the given database file does not exist, an error will be returned. Otherwise,
  the return value will be the result of the given function.

  Z/IP Gateway should be stopped prior to making any modifications to the database,
  otherwise it will ignore and most likely overwrite your changes. This function
  will return an error if Z/IP Gateway is running and the first argument. If you
  want to bypass this check, open the database and pass the connection handle.
  """
  @spec with_database(Path.t() | reference(), (Sqlite3.db() -> any())) :: any()
  def with_database(db, fun) when is_reference(db), do: fun.(db)

  def with_database(db_path, fun) when is_binary(db_path) do
    if File.exists?(db_path) do
      with {:ok, db} <- Sqlite3.open(db_path) do
        try do
          with_database(db, fun)
        after
          Sqlite3.close(db)
        end
      end
    else
      {:error, "Database file not found: #{db_path}"}
    end
  end

  @doc """
  Same as `with_database/2`, but uses the database file pointed to by `Grizzly.options/0`.
  """
  @spec with_database((Sqlite3.db() -> any())) :: any()
  def with_database(fun), do: with_database(Grizzly.options().database_file, fun)

  @doc """
  Looks up a node by its ID and returns a map or nil if not found.
  """
  @spec get_node(Sqlite3.db(), integer()) :: query_result(zwave_node() | nil)
  def get_node(db, node_id) do
    with {:ok, result} when not is_nil(result) <-
           select_one(db, "SELECT * FROM nodes WHERE nodeid = ?", [node_id]) do
      {:ok, decode_node_record(result)}
    end
  end

  @doc """
  Returns a list of all nodes.
  """
  @spec all_nodes(Sqlite3.db()) :: query_result([zwave_node()])
  def all_nodes(db) do
    with {:ok, results} <- select_all(db, "SELECT * FROM nodes") do
      {:ok, Enum.map(results, &decode_node_record/1)}
    end
  end

  @doc """
  Returns a list of all endpoints.
  """
  @spec all_endpoints(Sqlite3.db()) :: query_result([endpoint()])
  def all_endpoints(db) do
    with {:ok, results} <- select_all(db, "SELECT * FROM endpoints") do
      {:ok, Enum.map(results, &decode_endpoint_record/1)}
    end
  end

  @doc """
  Returns a list of the given node's endpoints.
  """
  @spec get_node_endpoints(Sqlite3.db(), integer()) :: query_result([map()])
  def get_node_endpoints(db, node_id),
    do: select_all(db, "SELECT * FROM endpoints WHERE nodeid = ?", [node_id])

  @doc """
  Looks up a endpoint by node id and endpoint id and returns a map or nil if not found.
  Returns endpoint 0 (the root device) if no endpoint_id is specified.
  """
  @spec get_endpoint(Sqlite3.db(), pos_integer(), non_neg_integer()) :: query_result(map() | nil)
  def get_endpoint(db, node_id, endpoint_id \\ 0),
    do:
      select_one(db, "SELECT * FROM endpoints WHERE nodeid = ? AND endpointid = ?", [
        node_id,
        endpoint_id
      ])

  @missing_endpoints_query """
  SELECT n.*
  FROM nodes n
  LEFT JOIN endpoints e ON n.nodeid = e.nodeid
  WHERE e.nodeid IS NULL
    AND n.nodeid != 1
  """

  @doc """
  Returns a list of nodes that have don't have any entries in the endpoints table.
  """
  @spec find_nodes_with_no_endpoints(Sqlite3.db()) :: query_result([map()])
  def find_nodes_with_no_endpoints(db), do: select_all(db, @missing_endpoints_query)

  @doc """
  Deletes a node (and its endpoints) from the database. The DSK field will be permanently
  lost, but that's probably not a major issue.
  """
  @spec delete_node(Sqlite3.db(), integer()) :: :ok | {:error, Sqlite3.reason()}
  def delete_node(_conn, 1), do: {:error, "Are you *trying* to break things?"}

  def delete_node(db, node_id) do
    with :ok <- Sqlite3.execute(db, "BEGIN"),
         :ok <- execute(db, "DELETE FROM nodes WHERE nodeid = ?", [node_id]),
         :ok <- execute(db, "DELETE FROM endpoints WHERE nodeid = ?", [node_id]) do
      Sqlite3.execute(db, "COMMIT")
    end
  end

  @doc """
  Prepares and executes the given query. Returns a list of maps, where map keys
  are column names and values are the corresponding row values.
  """
  @spec select_all(Sqlite3.db(), binary(), list()) :: query_result([map()])
  def select_all(db, query, bindings \\ []) do
    with_statement(db, query, fn stmt ->
      with :ok <- Sqlite3.bind(stmt, bindings),
           {:ok, cols} <- Sqlite3.columns(db, stmt),
           {:ok, rows} <- Sqlite3.fetch_all(db, stmt) do
        {:ok, rows_to_records(cols, rows)}
      end
    end)
  end

  @doc """
  Same as `select_all/3`, but returns only the first row or nil.
  """
  @spec select_one(Sqlite3.db(), binary(), list()) :: query_result(map() | nil)
  def select_one(db, query, bindings \\ []) do
    case select_all(db, query, bindings) do
      {:ok, []} -> {:ok, nil}
      {:ok, [row]} -> {:ok, row}
      {:ok, _} -> {:error, "Multiple rows returned"}
      error -> error
    end
  end

  @spec with_statement(Sqlite3.db(), binary(), (Sqlite3.statement() -> result)) :: result
        when result: var
  def with_statement(db, query, fun) do
    with {:ok, stmt} <- Sqlite3.prepare(db, query) do
      try do
        fun.(stmt)
      after
        Sqlite3.release(db, stmt)
      end
    end
  end

  @doc """
  Execute a query that doesn't return any rows. It is an error to use a select
  statement with this function.
  """
  @spec execute(Sqlite3.db(), binary(), list()) :: :ok | {:error, Sqlite3.reason()}
  def execute(db, query, bindings) do
    with_statement(db, query, fn stmt ->
      with :ok <- Sqlite3.bind(stmt, bindings),
           :done <- Sqlite3.step(db, stmt) do
        :ok
      else
        :busy -> {:error, "Database is busy (make sure Z/IP Gateway is not running)"}
        {:row, _} -> {:error, "Unexpected row returned"}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp rows_to_records(cols, rows), do: Enum.map(rows, &row_to_record(cols, &1))
  defp row_to_record(cols, row), do: cols |> Enum.zip(row) |> Map.new()

  @spec decode_node_record(map()) :: zwave_node()
  defp decode_node_record(node) do
    %{
      id: node["nodeid"],
      dsk: if(is_binary(node["dsk"]) and byte_size(node["dsk"]) == 16, do: DSK.new(node["dsk"])),
      last_awake: node["lastAwake"],
      last_update: node["lastUpdate"],
      manufacturer_id: node["manufacturerID"],
      product_type: node["productType"],
      product_id: node["productID"],
      mode: decode_mode_flags(node["mode"]),
      security_flags: decode_security_flags(node["security_flags"]),
      properties_flags: decode_properties_flags(node["properties_flags"]),
      probe_state: decode_probe_state(node["probe_flags"]),
      state: decode_node_state(node["state"]),
      version_capabilities: decode_version_capabilities(node["node_version_cap_and_zwave_sw"]),
      basic_device_class: elem(DeviceClasses.basic_device_class_from_byte(node["nodeType"]), 1),
      wake_up_interval: node["wakeUp_interval"]
    }
  end

  @spec decode_endpoint_record(map()) :: endpoint()
  defp decode_endpoint_record(endpoint) do
    {generic_class, specific_class, command_classes} =
      case endpoint["info"] do
        <<generic, specific, command_classes::binary>> ->
          {:ok, generic} = DeviceClasses.generic_device_class_from_byte(generic)
          {:ok, specific} = DeviceClasses.specific_device_class_from_byte(generic, specific)
          {generic, specific, CommandClasses.command_class_list_from_binary(command_classes)}

        _ ->
          {nil, nil, []}
      end

    %{
      id: endpoint["endpointid"],
      node_id: endpoint["nodeid"],
      generic_device_class: generic_class,
      specific_device_class: specific_class,
      command_classes: command_classes
    }
  end

  @doc """
  Decodes the bitmask stored in the `nodes.mode` field into a keyword list.
  """
  @spec decode_mode_flags(integer()) :: [mode_flag()]
  def decode_mode_flags(mode) when is_integer(mode) do
    mode_flag =
      cond do
        band(mode, 0xFF) == 0 -> :not_probed
        band(mode, 0xFF) == 1 -> :nonlistening
        band(mode, 0xFF) == 2 -> :always_listening
        band(mode, 0xFF) == 3 -> :flirs
        band(mode, 0xFF) == 4 -> :wakeup
        band(mode, 0xFF) == 5 -> :wakeup_firmware_upgrade
        true -> :unknown
      end

    deleted = band(mode, 0x0100) != 0
    failed = band(mode, 0x0200) != 0
    low_battery = band(mode, 0x0400) != 0

    [mode: mode_flag, deleted: deleted, failed: failed, low_battery: low_battery]
  end

  def decode_mode_flags(_mode), do: [mode: :unknown]

  @doc """
  Decodes a node's Version CC capabilities bitmask stored in the
  `nodes.node_version_cap_and_zwave_sw` field into a keyword list.
  """
  @spec decode_version_capabilities(integer()) :: [{version_capability(), boolean()}]
  def decode_version_capabilities(caps) do
    version_get = band(caps, 0x01) != 0
    version_command_class_get = band(caps, 0x02) != 0
    version_zwave_software_get = band(caps, 0x04) != 0

    [
      version_get: version_get,
      version_command_class_get: version_command_class_get,
      version_zwave_software_get: version_zwave_software_get
    ]
  end

  @doc """
  Decodes the bitmask stored in the `nodes.properties_flags` field into a keyword list.
  """
  @spec decode_properties_flags(integer()) :: [properties_flag()]
  def decode_properties_flags(properties_flags) do
    portable = band(properties_flags, 0x01) != 0

    just_added =
      if(band(properties_flags, 0x02) != 0,
        do: "true (probe not completed)",
        else: "false (probe completed)"
      )

    added_by =
      if(band(properties_flags, 0x04) != 0, do: "this controller", else: "another controller")

    [portable: portable, just_added: just_added, added_by: added_by]
  end

  @doc """
  Decodes the bitmask stored in the `nodes.security_flags` field into a keyword list.
  """
  @spec decode_security_flags(integer()) :: [security_flag()]
  def decode_security_flags(flags) do
    [
      s0: band(flags, 0x01) != 0,
      s2_unauthenticated: band(flags, 0x10) != 0,
      s2_authenticated: band(flags, 0x20) != 0,
      s2_access_control: band(flags, 0x40) != 0,
      known_bad: band(flags, 0x02) != 0
    ]
  end

  @doc """
  Decodes the bitmask stored in the `nodes.probe_flags` field into an atom.
  """
  @spec decode_probe_state(integer()) :: probe_state() | :unknown
  def decode_probe_state(probe_state) do
    case probe_state do
      0 -> :never_started
      1 -> :probe_started
      2 -> :probe_failed
      3 -> :ok
      _ -> :unknown
    end
  end

  @doc """
  Decodes the bitmask stored in the `nodes.state` field into an atom.
  """
  @spec decode_node_state(integer()) :: node_state() | :unknown
  def decode_node_state(state) do
    case state do
      0 -> :created
      1 -> :probe_node_info
      2 -> :probe_product_id
      3 -> :enumerate_endpoints
      4 -> :find_endpoints
      5 -> :check_wakeup_cc_version
      6 -> :get_wakeup_capabilities
      7 -> :set_wakeup_interval
      8 -> :assign_return_route
      9 -> :probe_wakeup_interval
      10 -> :probe_endpoints
      11 -> :mdns_probe
      12 -> :mdns_endpoint_probe
      13 -> :done
      14 -> :probe_fail
      15 -> :failing
      _ -> :unknown
    end
  end
end
