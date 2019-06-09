defmodule Grizzly.CommandClass.Configuration.Set do
  @moduledoc """
  Command module for working with the Configuration command class SET command

  Command Options:

    * `:config_param` - The parameter for the configuration item outlined in the device's Z-Wave spec
    * `:size` - The amount of bytes in terms of bytes: 1 = 1 byte, 2 = 2 bytes, etc.
    * `:args` - The arguments to the parameter as outlined in the device's Z-Wave spec
    * `:seq_number` - The sequence number used for the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Configuration

  @type t :: %__MODULE__{
          config_param: byte,
          size: non_neg_integer,
          arg: Configuration.param_arg(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:config_param, byte}
          | {:size, non_neg_integer}
          | {:arg, Configuration.param_arg()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct config_param: nil, size: nil, arg: nil, seq_number: nil, retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{arg: arg} = command) when is_list(arg) do
    binary =
      Packet.header(command.seq_number) <>
        <<0x70, 0x04, command.config_param, command.size>> <> :erlang.list_to_binary(arg)

    {:ok, binary}
  end

  def encode(%__MODULE__{arg: arg} = command) when is_integer(arg) do
    size = command.size
    arg_list = <<arg::signed-integer-size(size)-unit(8)>> |> :binary.bin_to_list()

    binary =
      Packet.header(command.seq_number) <>
        <<0x70, 0x04, command.config_param, command.size>> <> :erlang.list_to_binary(arg_list)

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, :ok}
          | {:retry, t()}
          | {:queued, t()}
  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
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
