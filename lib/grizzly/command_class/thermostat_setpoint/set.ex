defmodule Grizzly.CommandClass.ThermostatSetpoint.Set do
  @moduledoc """
  Command module to work with the ThermostatSetpoint command class SET command

  Command Options:

    * `:value` - What the value of the set-point should be
    * `:type` - The set-point type being targeted: `:cooling`, `:heating`, or a byte
    * `:opts` - A keyword list of `:precision`, `:scale`, and `:size`
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.ThermostatSetpoint

  @type t :: %__MODULE__{
          value: pos_integer,
          type: ThermostatSetpoint.setpoint_type(),
          opts: keyword,
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:value, pos_integer}
          | {:type, ThermostatSetpoint.setpoint_type()}
          | {:opts, keyword}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct value: nil,
            type: nil,
            opts: [precision: 0, scale: 8, size: 1],
            seq_number: nil,
            retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{
          value: value,
          type: _type,
          opts: [precision: _precision, scale: _scale, size: size],
          seq_number: seq_number
        } = command
      ) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             type: {:encode_with, ThermostatSetpoint, :encode_setpoint_type},
             opts: {:encode_with, ThermostatSetpoint, :encode_opts},
             value: {:bytes, size}
           }) do
      binary = Packet.header(seq_number) <> <<0x43, 0x01, encoded.type, encoded.opts, value>>
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
