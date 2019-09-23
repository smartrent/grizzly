defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.StatisticsClear do
  @moduledoc """
  Command module to work with the NetworkManagementInstallationMaintenance command class STATISTICS_CLEAR command

  Command Options:

    * `:node_id` - The id of the node on which to reset stored statistics
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          node_id: non_neg_integer(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:node_id, non_neg_integer()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  @enforce_keys [:node_id]

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
      binary = Packet.header(seq_number) <> <<0x67, 0x06, node_id::size(8)>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t} | {:done, {:error, :nack_response}} | {:done, :ok} | {:retry, t}
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

  def handle_response(command, _), do: {:continue, command}
end
