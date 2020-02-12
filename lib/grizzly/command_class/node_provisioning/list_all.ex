defmodule Grizzly.CommandClass.NodeProvisioning.ListAll do
  @moduledoc """
  This command is used to read the entire the provisioning list of a supporting node at once.

  Command Options:

     * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, DSK}
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          remaining_counter: non_neg_integer(),
          __buffer: []
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct seq_number: nil, remaining_counter: 0xFF, retries: 2, __buffer: []

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number, remaining_counter: remaining_counter} = command) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(command, %{
             remaining_counter: :byte
           }) do
      binary = Packet.header(seq_number) <> <<0x78, 0x03, seq_number, remaining_counter>>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response | :not_found}}
          | {:done,
             {:ok,
              [
                %{
                  dsk: DSK.dsk_string()
                }
              ]}}
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
        %__MODULE__{__buffer: buffer},
        %Packet{
          body: %{
            command_class: :node_provisioning,
            command: :list_iteration_report,
            value: %{remaining_count: 0} = list_iteration_report
          }
        }
      ) do
    info = %{dsk: dsk} = Map.drop(list_iteration_report, ~w(remaining_count seq_number)a)

    if dsk == nil do
      {:done, {:ok, Enum.reverse(buffer)}}
    else
      {:done, {:ok, Enum.reverse([info | buffer])}}
    end
  end

  def handle_response(
        %__MODULE__{__buffer: buffer} = command,
        %Packet{
          body: %{
            command_class: :node_provisioning,
            command: :list_iteration_report,
            value: %{remaining_count: remaining_count} = list_iteration_report
          }
        }
      ) do
    info = Map.drop(list_iteration_report, ~w(remaining_count seq_number)a)

    updated_command = %__MODULE__{
      command
      | remaining_counter: remaining_count,
        __buffer: [info | buffer]
    }

    {:retry, updated_command}
  end

  def handle_response(command, _), do: {:continue, command}
end
