defmodule Grizzly.CommandClass.SwitchBinary.Set do
  @moduledoc """
  Command module for working with SWITCH_BINARY SET command.

  command options:

    * `:value` - either `:on` or `:off`
    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number of times to resend the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.EncodeError
  alias Grizzly.CommandClass.SwitchBinary

  @type t :: %__MODULE__{
          value: SwitchBinary.switch_state(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  defstruct value: nil, seq_number: nil, retries: 2

  @type opts ::
          {:value, SwitchBinary.switch_state()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  @spec init([opts]) :: {:ok, t}
  def init(opts) do
    command = struct(__MODULE__, opts)
    {:ok, command}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{value: nil}) do
    {:error, EncodeError.new({:invalid_argument_value, :value, nil, __MODULE__})}
  end

  def encode(%__MODULE__{value: value, seq_number: seq_number}) do
    case SwitchBinary.encode_switch_state(value) do
      {:ok, value} ->
        {:ok, Packet.header(seq_number) <> <<0x25, 0x01, value>>}

      {:error, :invalid_arg, _} ->
        error = EncodeError.new({:invalid_argument_value, :value, value, __MODULE__})
        {:error, error}
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

  def handle_response(command, _) do
    {:continue, command}
  end
end
