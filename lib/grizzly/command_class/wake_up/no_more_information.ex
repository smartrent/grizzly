defmodule Grizzly.CommandClass.WakeUp.NoMoreInformation do
  @moduledoc """
  Command module for working with Wake Up command class WAKE_UP_NO_MORE_INFORMATION command
  Ref Docs: SDS13782 Z-Wave Management Command Class Specification.pdf
  Command Options:
    * `:seq_number` - The sequence number in the Z/IP Packet
    * `:retries` - The number to attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, Node}

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt :: {:seq_number, Grizzly.seq_number()} | {:retries, non_neg_integer()}

  defstruct seq_number: nil, retries: 2

  @impl true
  @spec init([opt]) :: {:ok, t()}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @impl true
  @spec encode(t()) :: {:ok, binary()}
  def encode(%__MODULE__{seq_number: seq_number}) do
    {:ok, Packet.header(seq_number) <> <<0x84, 0x08>>}
  end

  @impl true
  @spec handle_response(t(), Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:retry, t()}
          | {:done, %{seconds: non_neg_integer(), node_id: Node.node_id()}}
          | {:queued, t()}
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

  def handle_response(command, _) do
    {:continue, command}
  end
end
