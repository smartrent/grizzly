defmodule Grizzly.CommandClass.ThermostatFanMode.Set do
  @moduledoc """
  Command module for the ThermostatFanMode command class SET command

  Command Options:

    * `:mode` - The mode of the fan: `:auto_low`, `:low`, `:auto_high`, `:high`,
               `:auto_medium`, `:medium`, `:circulation`, `:humidity_circulation`,
               `:left_right`, `:up_down`, `:quiet`
    * `:seq_number` - The sequence number for the packet
    * `:retries` - The number of times the command should be retried (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatFanMode

  @type t :: %__MODULE__{
          mode: ThermostatFanMode.thermostat_fan_mode(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:mode, ThermostatFanMode.thermostat_fan_mode()}
          | {:seq_number, Grizzly.seq_number(), retries: non_neg_integer()}

  defstruct mode: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(args) do
    {:ok, struct(__MODULE__, args)}
  end

  def encode(%__MODULE__{mode: mode, seq_number: seq_number}) do
    mode = ThermostatFanMode.encode_thermostat_fan_mode(mode)
    binary = Packet.header(seq_number) <> <<0x44, 0x01, mode>>
    {:ok, binary}
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

  def handle_response(command, _), do: {:continue, command}
end
