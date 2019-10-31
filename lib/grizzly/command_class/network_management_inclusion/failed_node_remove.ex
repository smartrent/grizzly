defmodule Grizzly.CommandClass.NetworkManagementInclusion.FailedNodeRemove do
  @moduledoc """
  A module for working with the FAILED_NODE_REMOVE command

  This command is used for removing failed nodes
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.NetworkManagementInclusion

  @typedoc """
  Mode for the controller to use during exclusion

  - `:node_id` - the id of the failed node to be removed
  """

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          node_id: byte
        }

  defstruct node_id: nil,
            retries: 2,
            seq_number: nil

  def init(args) do
    {:ok, struct(__MODULE__, args)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{node_id: node_id, seq_number: seq_number} = command) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(command, %{
             node_id: :byte
           }) do
      binary = Packet.header(seq_number) <> <<0x34, 0x07, seq_number, node_id>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, NetworkManagementInclusion.failed_node_remove_report()}
          | {:retry, t}

  def handle_response(%__MODULE__{seq_number: seq_number} = command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:continue, command}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: 0}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: n} = command, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
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

  def handle_response(
        _,
        %Packet{
          body: %{
            command_class: :network_management_inclusion,
            command: :failed_node_remove_status,
            value: report
          }
        }
      ) do
    {:done, {:ok, report}}
  end

  def handle_response(command, _), do: {:continue, command}
end
