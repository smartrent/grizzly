defmodule Grizzly.CommandClass.UserCode.Set do
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.UserCode

  @type t :: %__MODULE__{
          slot_id: pos_integer,
          slot_status: UserCode.slot_status(),
          user_code: UserCode.user_code(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:slot_id, pos_integer}
          | {:slot_status, UserCode.slot_status()}
          | {:user_code, UserCode.user_code()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct slot_id: nil, slot_status: nil, user_code: [], seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{} = command) do
    user_code = UserCode.encode_user_code(command.user_code)
    status = UserCode.status_to_hex(command.slot_status)

    binary =
      Packet.header(command.seq_number) <>
        <<0x63, 0x01, command.slot_id, status>> <> :erlang.list_to_binary(user_code)

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
