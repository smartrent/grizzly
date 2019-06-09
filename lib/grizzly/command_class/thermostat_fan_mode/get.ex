defmodule Grizzly.CommandClass.ThermostatFanMode.Get do
  @moduledoc """
  Module for the ThermostatFanMode command class GET command.


  Command options:

    * `:seq_number` - The sequence number for the packet
    * `:retries` - The amount of times to retry the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatFanMode

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt :: {:seq_number, Grizzly.seq_number()} | {:retries, non_neg_integer}

  defstruct seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts), do: {:ok, struct(__MODULE__, opts)}

  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x44, 0x02>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, ThermostatFanMode.thermostat_fan_mode()}
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

  def handle_response(
        _command,
        %Packet{
          body: %{command: :report, value: fan_mode_command, command_class: :thermostat_fan_mode}
        }
      ) do
    {:done, {:ok, fan_mode_command}}
  end

  def handle_response(command, _), do: {:continue, command}
end
