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
  alias Grizzly.Command.{EncodeError, Encoding}
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

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{mode: _mode, seq_number: seq_number} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             mode: {:encode_with, ThermostatFanMode, :encode_thermostat_fan_mode}
           }) do
      binary = Packet.header(seq_number) <> <<0x44, 0x01, encoded.mode>>
      {:ok, binary}
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

  def handle_response(command, _), do: {:continue, command}
end
