defmodule Grizzly.CommandClass.Configuration.BulkGet do
  @moduledoc """
  Command module for working with the Configuration command class BULK_GET command


  Command Options:

    * `:start` - the starting number of the configuration params
    * `:number` - the number of params to get
    * `:seq_number` the sequence number used by Z/IP packet
    * `:parameter_values` - a list of the parameter values that are returned from Z-Wave
    * `:acked` - if there the command has successfully acked by Z-Wave
    * `:retries` - the number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  require Logger

  @type t :: %__MODULE__{
          start: integer,
          number: byte,
          seq_number: Grizzly.seq_number(),
          parameter_values: [],
          acked: boolean,
          retries: non_neg_integer()
        }

  @type opt ::
          {:start, integer}
          | {:number, byte}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct start: nil,
            number: nil,
            seq_number: nil,
            acked: false,
            parameter_values: [],
            retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{seq_number: seq_number, start: start, number: number}) do
    binary =
      Packet.header(seq_number) <>
        <<0x70, 0x08, start::size(2)-big-integer-signed-unit(8), number>>

    {:ok, binary}
  end

  @spec handle_response(t(), Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, {:ok, %{start: any, values: any}}}
          | {:queued, t()}
          | {:retry, t()}
  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ),
      do: {:done, {:error, :nack_response}}

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ),
      do: {:retry, %{command | retries: n - 1}}

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

  def handle_response(
        %__MODULE__{acked: false, seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:continue, %__MODULE__{command | acked: true}}
  end

  def handle_response(
        %__MODULE__{parameter_values: parameter_values, acked: true},
        %Packet{
          body:
            %{
              command_class: Grizzly.CommandClass.Configuration,
              command: :bulk_report,
              to_follow: 0,
              parameter_offset: parameter_offset,
              values: values
            } = body
        }
      ) do
    _ = Logger.debug("Handling last bulk report #{inspect(body)}")

    {:done, {:ok, %{start: parameter_offset, values: parameter_values ++ values}}}
  end

  def handle_response(
        %__MODULE__{parameter_values: parameter_values, acked: true} = command,
        %Packet{
          body:
            %{
              command_class: Configuration,
              command: :bulk_report,
              to_follow: n,
              parameter_offset: _parameter_offset,
              values: values
            } = body
        }
      ) do
    _ = Logger.debug("Handling partial bulk report #{inspect(body)} (#{n} to follow)")

    {:continue, %__MODULE__{command | parameter_values: parameter_values ++ values}}
  end

  def handle_response(command, _packet) do
    {:continue, command}
  end
end
