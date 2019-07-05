defmodule Grizzly.CommandClass.TimeParameters.Set do
  @moduledoc "Set command for the time parameters command class"
  @behaviour Grizzly.Command

  alias Grizzly.Packet
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

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{
        value: %{
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second
        },
        seq_number: seq_number
      }) do
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
