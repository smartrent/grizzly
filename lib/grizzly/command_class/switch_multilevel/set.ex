defmodule Grizzly.CommandClass.SwitchMultilevel.Set do
  @moduledoc """
  Command module for working with SWITCH_MULTILEVEL SET command.

  command options:

    * `:value` - A number between 0 and 99 for the switch level
    * `:seq_number` - The sequence number for the Z/IP Packet
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.SwitchMultilevel

  @type t :: %__MODULE__{
          value: SwitchMultilevel.switch_state(),
          seq_number: Grizzly.seq_number()
        }

  defstruct value: nil, seq_number: nil

  @type opts :: {:value, SwitchMultilevel.switch_state()} | {:seq_number, Grizzly.seq_number()}

  @spec init([opts]) :: {:ok, t}
  def init(opts) do
    command = struct(__MODULE__, opts)
    {:ok, command}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{value: value, seq_number: seq_number}) do
    value = SwitchMultilevel.encode_switch_state(value)
    binary = Packet.header(seq_number) <> <<0x26, 0x01, value>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t} | {:done, {:error, :nack_response}} | {:done, :ok}
  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
  end

  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(command, _) do
    {:continue, command}
  end
end
