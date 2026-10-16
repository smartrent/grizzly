defmodule Grizzly.ZIPGateway.Database do
  @moduledoc "ZIPGateway compatibility facade for shared directory queries/decoders."
  alias Grizzly.Directory.Database

  @type query_result(result) :: Database.query_result(result)
  @type security_flag() :: Database.security_flag()
  @type probe_state() :: Database.probe_state()
  @type node_state() :: Database.node_state()
  @type node_mode() :: Database.node_mode()
  @type mode_flag() :: Database.mode_flag()
  @type properties_flag() :: Database.properties_flag()
  @type version_capability() :: Database.version_capability()
  @type zwave_node() :: Database.zwave_node()
  @type endpoint() :: Database.endpoint()
  @type listening_mode() :: Database.listening_mode()
  defdelegate with_database(fun), to: Database
  defdelegate with_database(path, fun), to: Database
  defdelegate clear_s2_sessions(db), to: Database
  defdelegate get_node(db, id), to: Database
  defdelegate all_nodes(db), to: Database
  defdelegate all_endpoints(db), to: Database
  defdelegate get_node_endpoints(db, id), to: Database
  defdelegate get_endpoint(db, id), to: Database
  defdelegate get_endpoint(db, id, endpoint), to: Database
  defdelegate find_nodes_with_no_endpoints(db), to: Database
  defdelegate delete_node(db, id), to: Database
  defdelegate select_all(db, query), to: Database
  defdelegate select_all(db, query, bindings), to: Database
  defdelegate select_one(db, query), to: Database
  defdelegate select_one(db, query, bindings), to: Database
  defdelegate with_statement(db, query, fun), to: Database
  defdelegate execute(db, query, bindings), to: Database
  defdelegate listening_mode(id), to: Database
  defdelegate decode_mode_flags(value), to: Database
  defdelegate decode_version_capabilities(value), to: Database
  defdelegate decode_properties_flags(value), to: Database
  defdelegate decode_security_flags(value), to: Database
  defdelegate decode_probe_state(value), to: Database
  defdelegate decode_node_state(value), to: Database
end
