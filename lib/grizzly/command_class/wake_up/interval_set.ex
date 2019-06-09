defmodule Grizzly.CommandClass.WakeUp.IntervalSet do
  @moduledoc """
  Command module for working with the Wake Up command class INTERVAL_SET command
  Ref Docs: SDS13782 Z-Wave Management Command Class Specification.pdf
  Command Options:
    * `:seconds` - The number seconds for the device to wake up between 0 and 16777215
    * `:node_id` - The node that the device should send the wake up notification to
    * `:seq_number` - The sequence number used for the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, Node}

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          seconds: non_neg_integer(),
          node_id: Node.node_id()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:seconds, non_neg_integer()}
          | {:node_id, Node.node_id()}

  @enforce_keys [:seconds, :node_id]
  defstruct seq_number: nil, retries: 2, seconds: nil, node_id: nil

  @impl true
  @spec init([opt]) :: {:ok, t()}
  def init(opts) do
    {:ok, struct!(__MODULE__, opts)}
  end

  @impl true
  @spec encode(t()) :: {:ok, binary()}
  def encode(%__MODULE__{seq_number: seq_number, seconds: seconds, node_id: node_id}) do
    packet = Packet.header(seq_number) <> <<0x084, 0x04, seconds::size(24), node_id>>
    {:ok, packet}
  end

  @impl true
  @spec handle_response(t(), Packet.t()) ::
          {:done, :ok} | {:done, {:error, :nack_response}} | {:queued, t()} | {:retry, t()}
  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
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

  def handle_response(%__MODULE__{} = command, %Packet{}), do: {:continue, command}
end
