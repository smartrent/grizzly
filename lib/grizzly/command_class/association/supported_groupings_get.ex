defmodule Grizzly.CommandClass.Association.SupportedGroupingsGet do
  @moduledoc """
  Command module for working with ASSOCIATION_GROUPINGS_GET command.

  command options:

    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number of times to resend the command (default 2)
  """

  @behaviour Grizzly.Command

  alias Grizzly.Packet

  @type t :: %__MODULE__{
          seq_number: non_neg_integer() | nil,
          retries: non_neg_integer()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct seq_number: nil, retries: 2

  @impl true
  @spec init([opt]) :: {:ok, t()}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @impl true
  @spec encode(t()) :: {:ok, binary()}
  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x85, 0x05>>
    {:ok, binary}
  end

  @impl true
  @spec handle_response(t(), Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, {:ok, byte}}
          | {:queued, t()}
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
        %__MODULE__{},
        %Packet{
          body: %{
            command_class: :association,
            command: :association_groupings_report,
            value: supported_groupings
          }
        }
      ) do
    {:done, {:ok, supported_groupings}}
  end

  def handle_response(%__MODULE__{} = command, _), do: {:continue, command}
end
