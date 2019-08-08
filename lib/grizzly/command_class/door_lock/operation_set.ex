defmodule Grizzly.CommandClass.DoorLock.OperationSet do
  @moduledoc """
  Command for working with DOOR_LOCK command class OPERATION_GET command

  Command Options:

    * `:mode` - `:secured` for locked, `:unsecured` for unlocked
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """

  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.DoorLock

  @type t :: %__MODULE__{
          mode: DoorLock.door_lock_mode(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer
        }

  @type opt ::
          {:mode, DoorLock.door_lock_mode()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer}

  defstruct mode: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    command = struct(__MODULE__, opts)
    {:ok, command}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{mode: mode, seq_number: seq_number}) do
    mode = DoorLock.encode_mode(mode)
    binary = Packet.header(seq_number) <> <<0x62, 0x01, mode>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, :ok}
          | {:retry, t()}
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

  def handle_response(command, _), do: {:continue, command}
end
