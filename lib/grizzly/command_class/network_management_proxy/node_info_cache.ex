defmodule Grizzly.CommandClass.NetworkManagementProxy.NodeInfoCache do
  @moduledoc """
  Command module for working with the NetworkManagementProxy command class NODE_INFO_CACHE command

  Command Options:

    * `:cached_minutes_passed` - the minutes passed since the information was cached, if the cache has been longer than requested it will get the information
    * `:node_id` - the id of the node that the information is requested about
    * `:seq_number` - the sequence number used by the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Node, Packet}
  alias Grizzly.Network.State, as: NetworkState

  @type t :: %__MODULE__{
          cached_minutes_passed: 0..15,
          node_id: Node.node_id(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          pre_states: [NetworkState.state()]
        }

  @type opt ::
          {:cached_minutes_passed, 0..15}
          | {:node_id, Node.node_id()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:pre_states, [NetworkState.state()]}

  defstruct cached_minutes_passed: nil,
            node_id: nil,
            seq_number: nil,
            retries: 2,
            pre_states: [:not_ready, :idle]

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{
        cached_minutes_passed: cached_minutes_passed,
        node_id: node_id,
        seq_number: seq_number
      }) do
    binary =
      Packet.header(seq_number) <> <<0x52, 0x03, seq_number, cached_minutes_passed, node_id>>

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, report :: any}
          | {:retry, t}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:continue, command}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _command,
        %Packet{
          body: %{
            command: :node_info_cache_report,
            report: report
          }
        }
      ) do
    {:done, {:ok, report}}
  end

  def handle_response(command, _), do: {:continue, command}
end
