defmodule Grizzly.CommandClass.NetworkManagementBasic.DSKGet do
  @moduledoc """
  Command module for working with the NetworkManagementBasic command class DSK_GET command

  Command Options:

    * `:add_mode` - the controller has two different DSKs for S2, one for
       learn (`:learn`) mode and one for normal inclusion (this is called `:add`)
    * `:seq_number` - the sequence number used for the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementBasic
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          add_mode: NetworkManagementBasic.add_mode()
        }

  @type opt :: {:seq_number, Grizzly.seq_number()} | {:retries, non_neg_integer()}

  defstruct seq_number: nil,
            retries: 2,
            add_mode: :add

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t()) :: {:ok, binary()} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             add_mode: {:encode_with, NetworkManagementBasic, :encode_add_mode}
           }) do
      binary = Packet.header(seq_number) <> <<0x4D, 0x08, seq_number, encoded.add_mode()>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, NetworkManagementBasic.dsk_get_report()}
          | {:retry, t}
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
        _command,
        %Packet{
          body: %{
            command: :dsk_report,
            report: report
          }
        }
      ) do
    {:done, {:ok, report}}
  end

  def handle_response(command, _), do: {:continue, command}
end
