defmodule Grizzly.CommandClass.NetworkManagementProxy.NodeListGet do
  @moduledoc """
  Command module for working with the NetworkManagementProxy command class NODE_LIST_GET command

  Command Options:

    * `:seq_number` - the sequence number used for the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, Node}
  alias Grizzly.Network.State, as: NetworkState

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          pre_states: [NetworkState.state()]
        }

  defstruct seq_number: nil, retries: 2, pre_states: [:not_ready, :idle]

  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x52, 0x01, seq_number>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t} | {:done, {:error, :nack_response}} | {:done, [Node.t()]} | {:retry, t}
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
        _,
        %Packet{
          body: %{command_class: :network_management_proxy, command: :node_list_report} = report
        }
      ) do
    {:done, {:ok, report.node_list}}
  end

  def handle_response(command, _), do: {:continue, command}
end
