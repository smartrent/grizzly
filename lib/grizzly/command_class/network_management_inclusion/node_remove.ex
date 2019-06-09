defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeRemove do
  @moduledoc """
  A module for working with the NODE_REMOVE command

  This command is used for activing or de-activing the node
  remove mode.
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, Node}
  alias Grizzly.Network.State, as: NetworkState

  @typedoc """
  Mode for the controller to use during exclusion

  - `:any` - remove any type of node from the network (default)
  - `:stop` - stop the node removal process
  """
  @type mode :: :any | :stop

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          mode: mode | byte,
          pre_states: [NetworkState.state()],
          exec_state: NetworkState.state(),
          timeout: non_neg_integer
        }

  defstruct mode: :any,
            seq_number: nil,
            pre_states: nil,
            exec_state: nil,
            timeout: nil

  def init(args) do
    {:ok, struct(__MODULE__, args)}
  end

  def encode(%__MODULE__{mode: mode, seq_number: seq_number}) do
    mode = encode_mode(mode)
    binary = Packet.header(seq_number) <> <<0x34, 0x03, seq_number, 0x00, mode>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, Node.node_id()}
          | {:done, {:error, :node_remove_failed}}

  def handle_response(
        %__MODULE__{seq_number: seq_number, mode: :stop},
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, {:ok, :node_remove_stopped}}
  end

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
            command: :node_remove_status,
            status: :failed
          }
        }
      ) do
    {:done, {:error, :node_remove_failed}}
  end

  def handle_response(
        _,
        %Packet{
          body: %{
            command: :node_remove_status,
            node_id: node_id,
            status: :done
          }
        }
      ) do
    {:done, {:ok, node_id}}
  end

  def handle_response(command, _), do: {:continue, command}

  @spec encode_mode(mode) :: byte
  def encode_mode(:any), do: 0x01
  def encode_mode(:stop), do: 0x05
  def encode_mode(mode) when mode in [0x01, 0x05], do: mode
end
