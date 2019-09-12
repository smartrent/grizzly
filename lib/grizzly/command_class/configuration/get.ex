defmodule Grizzly.CommandClass.Configuration.Get do
  @moduledoc """
  Command module for working with Configuration command class GET command

  Command Option:

    * `:configuration_param` - The configuration parameter outlined in the devices spec
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to the send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.Configuration

  @type t :: %__MODULE__{
          configuration_param: Configuration.param_arg(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:configuration_param, pos_integer}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct configuration_param: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{seq_number: seq_number, configuration_param: configuration_param} = command
      ) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(command, %{
             configuration_param: :byte
           }) do
      binary = Packet.header(seq_number) <> <<0x70, 0x05, configuration_param>>
      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, non_neg_integer()}
          | {:retry, t()}
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

  def handle_response(_command, %Packet{
        body: %{command_class: Configuration, command: :report, value: value}
      }) do
    {:done, {:ok, value}}
  end

  def handle_response(command, _), do: {:continue, command}
end
