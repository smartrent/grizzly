defmodule Grizzly.CommandClass.MultiChannelAssociation.Set do
  @moduledoc """
  Command module for working with MULTI_CHANNEL_ASSOCIATION_SET command.

   Command Options:

    * `:group` - The association group
    * `:nodes` - List of node ids to receive messages about node events
    * `:endpoints` - List of endpoints corresponding one-to-one to the nodes
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.MultiChannelAssociation

  @type t :: %__MODULE__{
          group: byte,
          nodes: MultiChannelAssociation.associated_nodes(),
          endpoints: MultiChannelAssociation.endpoints(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opts ::
          {:group, byte}
          | {:nodes, MultiChannelAssociation.associated_nodes()}
          | {:endpoints, MultiChannelAssociation.endpoints()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct group: nil,
            nodes: [],
            endpoints: [],
            seq_number: nil,
            retries: 2

  @spec init([opts]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{group: group, nodes: nodes, endpoints: endpoints, seq_number: seq_number} =
          command
      ) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(
             command,
             %{
               group: {:range, 2, 255},
               nodes: [:byte],
               endpoints: [%{node_id: {:range, 1, 127}, endpoint: :byte}]
             }
           ) do
      encoded_nodes = :erlang.list_to_binary(nodes)
      {:ok, encoded_node_endpoints} = MultiChannelAssociation.encode_endpoints(endpoints)

      binary =
        Packet.header(seq_number) <>
          <<0x8E, 0x01, group>> <>
          encoded_nodes <> <<MultiChannelAssociation.marker()>> <> encoded_node_endpoints

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, :ok}
          | {:retry, t()}
          | {:queued, t()}
  def handle_response(
        %__MODULE__{seq_number: seq_number},
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, :ok}
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
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response, :nack_waiting]
        } = packet
      ) do
    if Packet.sleeping_delay?(packet) do
      {:queued, command}
    else
      {:continue, command}
    end
  end

  def handle_response(command, _), do: {:continue, command}
end
