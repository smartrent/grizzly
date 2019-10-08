defmodule Grizzly.CommandClass.Version.Get do
  @moduledoc """
  Module for working with the `VERSION GET` command.

  This is for getting version information about the module Z-Wave

  Command Options:

    * `:seq_number` - the sequence number used by the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
  """

  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Version

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{seq_number: seq_number}) do
    {:ok, Packet.header(seq_number) <> <<0x86, 0x11>>}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, {:ok, Version.version_report()}}
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

  def handle_response(_command, %Packet{
        body:
          %{
            command_class: Version,
            command: :version_report
          } = body
      }) do
    {:done, {:ok, Map.drop(body, [:command_class, :command])}}
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
