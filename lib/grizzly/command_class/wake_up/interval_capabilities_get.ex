defmodule Grizzly.CommandClass.WakeUp.IntervalCapabilitiesGet do
  @behaviour Grizzly.Command

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  defstruct seq_number: nil, retries: 2

  alias Grizzly.Packet

  @spec init(keyword) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t()) :: {:ok, binary}
  def encode(%__MODULE__{seq_number: seq_number}) do
    binary = Packet.header(seq_number) <> <<0x84, 0x09>>
    {:ok, binary}
  end

  @spec handle_response(t(), Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, non_neg_integer()}
          | {:retry, t()}
          | {:queued, t()}
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

  def handle_response(%__MODULE__{}, %Packet{
        body:
          %{
            command_class: :wake_up,
            command: :interval_capabilities_report
          } = body
      }) do
    {:done, {:ok, Map.drop(body, [:command_class, :command])}}
  end

  def handle_response(%__MODULE__{} = command, %Packet{}) do
    {:continue, command}
  end
end
