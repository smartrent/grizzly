defmodule Grizzly.CommandClass.NodeProvisioning.ListIterationGet do
  @moduledoc """
  This command is used to read the entire the provisioning list of a supporting node.

  Command Options:

    * `:remaining_counter` - The field indicates the remaining amount of entries in the Provisioning List. Defaults to 0xFF when starting the iteration.
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2) 
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Packet, DSK}
  alias Grizzly.Command.{EncodeError, Encoding}

  @type t :: %__MODULE__{
          remaining_counter: non_neg_integer(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:remaining_counter, non_neg_integer()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct remaining_counter: 0xFF, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{remaining_counter: remaining_counter, seq_number: seq_number} = command) do
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
              %{
                seq_number: non_neg_integer,
                remaining_count: non_neg_integer,
                dsk: DSK.dsk_string()
              }}}
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
        _command,
        %Packet{
          body: %{
            command_class: :node_provisioning,
            command: :list_iteration_report,
            value: list_iteration_report
          }
        }
      ) do
    {:done, {:ok, list_iteration_report}}
  end

  def handle_response(command, _), do: {:continue, command}
end
