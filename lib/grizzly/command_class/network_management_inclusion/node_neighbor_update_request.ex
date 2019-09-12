defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeNeighborUpdateRequest do
  @moduledoc """
  Module for using the NODE_NEIGHBOR_UPDATE_REQUEST command.

  This command is used to instruct a node with NodeID to perform a Node Neighbor Update operation in
  order to update the topology on the controller.
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer,
          node_id: byte
        }

  @type opt ::
          {:node_id, byte}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  @type status :: :done | :failed

  defstruct node_id: nil,
            seq_number: nil,
            retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{node_id: node_id, seq_number: seq_number} = command) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(command, %{
             node_id: :byte
           }) do
      binary = Packet.header(seq_number) <> <<0x34, 0x0B, seq_number, node_id>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, status}
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
        %__MODULE__{seq_number: seq_number},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number},
        %Packet{
          seq_number: seq_number,
          body: %{
            command: :node_neighbor_update_status,
            status: status
          }
        }
      ) do
    {:done, {:ok, status}}
  end

  def handle_response(command, _), do: {:continue, command}
end
