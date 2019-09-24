defmodule Grizzly.CommandClass.TimeParameters.Set do
  @moduledoc """
  Command module for working with TIME_PARAMETERS SET command

  command options:

    * `:year` - Year in the usual Gregorian calendar
    * `:month` - Month of the year between 01 (January) and 12 (December) 
    * `:day` - Day of the month between 01 and 31 
    * `:hour` - Number of complete hours that have passed since midnight (00..23) in UTC
    * `:minute` - Number of complete minutes that have passed since the start of the hour (00..59) in UTC
    * `:second` - Number of complete seconds since the start of the minute (00..59) in UTC
    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number times to retry to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.TimeParameters

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          value: TimeParameters.date_time()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:value, TimeParameters.date_time()}

  defstruct seq_number: nil, retries: 2, value: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{
          value: %{
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
          },
          seq_number: seq_number
        } = command
      ) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(
             command,
             %{
               year: {:bytes, 2},
               month: {:range, 1, 12},
               day: {:range, 1, 31},
               hour: {:range, 0, 24},
               minute: {:range, 0, 59},
               second: {:range, 0, 59}
             },
             [:value]
           ) do
      binary =
        Packet.header(seq_number) <>
          <<
            0x8B,
            0x01,
            year::size(16),
            month::size(8),
            day::size(8),
            hour::size(8),
            minute::size(8),
            second::size(8)
          >>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, TimeParameters.date_time()}
          | {:retry, t}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = _command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, :ok}
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
        _,
        %Packet{
          body: %{
            command_class: :time_parameters,
            command: :report,
            value: value
          }
        }
      ) do
    {:done, {:ok, value}}
  end

  def handle_response(command, _), do: {:continue, command}
end
