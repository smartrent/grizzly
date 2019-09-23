defmodule Grizzly.CommandClass.ScheduleEntryLock.EnableAllSet do
  @moduledoc """
  Command for working with SCHEDULE_ENTRY_LOCK command class ENABLE_ALL_SET command

  Command Options:
    
    * `:value` - `:enable` or `:disable` all schedules for the EntryLock
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.ScheduleEntryLock

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          value: ScheduleEntryLock.enabled_value()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:value, ScheduleEntryLock.enabled_value()}

  defstruct seq_number: nil, retries: 2, value: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{value: _value, seq_number: seq_number} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             value: {:encode_with, ScheduleEntryLock, :encode_enabled_value}
           }) do
      binary = Packet.header(seq_number) <> <<0x4E, 0x02, encoded.value>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, :ok}
          | {:retry, t}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = _command,
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

  def handle_response(command, _response) do
    {:continue, command}
  end
end
