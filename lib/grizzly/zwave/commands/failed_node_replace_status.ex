defmodule Grizzly.ZWave.Commands.FailedNodeReplaceStatus do
  @moduledoc """
  Command for FAILED_NODE_REPLACE_STATUS

  Params:

    * `:seq_number` - the sequence number for the network command (required)
    * `:status` - the status of the inclusion
    * `:node_id` - the id of the node being replaced
    * `:granted_keys` - the security keys granted during S2 inclusion (optional)
    * `:kex_fail_type` - the error that occurred during S2 inclusion (optional)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.Security

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:status, NetworkManagementInclusion.node_add_status()}
          | {:node_id, Grizzly.node_id()}
          | {:granted_keys, [Security.key()]}
          | {:kex_fail_type, Security.key_exchange_fail_type()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    status = Command.param!(command, :status)
    node_id = Command.param!(command, :node_id)
    granted_keys = Command.param!(command, :granted_keys)
    kex_fail_type = Command.param!(command, :kex_fail_type)

    <<seq_number, NetworkManagementInclusion.node_add_status_to_byte(status), node_id,
      Security.keys_to_byte(granted_keys), Security.failed_type_to_byte(kex_fail_type)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, status, node_id, granted_keys, kex_fail_type>>) do
    {:ok,
     [
       seq_number: seq_number,
       status: NetworkManagementInclusion.parse_node_add_status(status),
       node_id: node_id,
       granted_keys: Security.byte_to_keys(granted_keys),
       kex_fail_type: Security.failed_type_from_byte(kex_fail_type)
     ]}
  end
end
