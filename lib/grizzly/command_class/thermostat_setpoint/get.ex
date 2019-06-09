defmodule Grizzly.CommandClass.ThermostatSetpoint.Get do
  @moduledoc """
  Command module for working with ThermostatSetpoint command class GET command

  Command Options:

    * `:type` - The set-point type: `:cooling`, `:heating`, or a byte
    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number of times to resend the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatSetpoint

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          type: ThermostatSetpoint.setpoint_type(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:type, ThermostatSetpoint.setpoint_type()}
          | {:retries, non_neg_integer()}

  defstruct type: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{type: type, seq_number: seq_number}) do
    type = ThermostatSetpoint.encode_setpoint_type(type)
    binary = Packet.header(seq_number) <> <<0x43, 0x02, type>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, ThermostatSetpoint.setpoint_value()}
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

  def handle_response(_, %Packet{
        body: %{command: :report, value: value, command_class: :thermostat_setpoint}
      }) do
    {:done, {:ok, value}}
  end

  def handle_response(command, _), do: {:continue, command}
end
