defmodule Grizzly.CommandClass.Battery.Get do
  @moduledoc """
  Command module for working with Battery command class GET command

  Command Options:

    * `:seq_number` - The sequence number in the Z/IP Packet
    * `:retries` - The number to attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  defstruct seq_number: nil, retries: 2

  @spec init(keyword) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x80, 0x02>>
    {:ok, binary}
  end

  @spec handle_response(t(), Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, non_neg_integer}
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
        body: %{command_class: :battery, command: :report, value: battery_level}
      }) do
    {:done, {:ok, battery_level}}
  end

  def handle_response(command, _), do: {:continue, command}
end
