defmodule Grizzly.CommandClass.SwitchMultilevel.Get do
  @moduledoc """
  Command module for working with SWITCH_MULTILEVEL GET command.

  command options:

    * `:seq_number` - The sequence number for the Z/IP Packet
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.SwitchMultilevel

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number()
        }

  @type opt :: {:seq_number, Grizzly.seq_number()}

  defstruct seq_number: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x26, 0x02>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, SwitchMultilevel.switch_state()}
  def handle_response(%__MODULE__{seq_number: seq_number} = command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:continue, command}
  end

  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        _,
        %Packet{body: %{command_class: :switch_multilevel, command: :report, value: switch_state}}
      ) do
    {:done, {:ok, switch_state}}
  end

  def handle_response(command, _), do: {:continue, command}
end
