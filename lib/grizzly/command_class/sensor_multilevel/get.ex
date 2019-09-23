defmodule Grizzly.CommandClass.SensorMultilevel.Get do
  @moduledoc """
  Command module for working with the SensorMultilevel command class GET command

  Command Options:
    
    * `:seq_number` - the sequence number used for Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.MultilevelSensor

  @type t :: %__MODULE__{
          sensor_type: MultilevelSensor.level_type(),
          sensor_scale: non_neg_integer,
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt :: {:seq_number, Grizzly.seq_number()} | {:retries, non_neg_integer()}

  defstruct sensor_type: nil, sensor_scale: 1, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{
        seq_number: seq_number,
        sensor_type: nil,
        sensor_scale: _sensor_scale
      }) do
    {:ok, Packet.header(seq_number) <> <<0x31, 0x04>>}
  end

  def encode(
        %__MODULE__{
          seq_number: seq_number,
          sensor_type: _sensor_type,
          sensor_scale: sensor_scale
        } = command
      ) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             sensor_type: {:encode_with, MultilevelSensor, :encode_type},
             sensor_scale: {:bytes, 2}
           }) do
      binary =
        Packet.header(seq_number) <>
          <<
            0x31,
            0x04,
            encoded.sensor_type,
            0x00::size(3),
            sensor_scale || 1::size(2),
            0x00::size(3)
          >>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, non_neg_integer}
          | {:retry, t}
          | {:queued, t()}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:continue, command}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _command,
        %Packet{
          body: %{
            command_class: :sensor_multilevel,
            command: :report,
            value: value
          }
        }
      ) do
    {:done, {:ok, value}}
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

  def handle_response(command, _), do: {:continue, command}
end
