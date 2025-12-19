defmodule Grizzly.ZWave.Commands.DefaultSetComplete do
  @moduledoc """
  Command to indicate the result of a `Grizzly.ZWave.Commands.DefaultSet`
  operation

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:status` - the status of the default set operation (required)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode
  alias Grizzly.ZWave.DecodeError

  @type status :: :done | :busy

  @type param :: {:seq_number, ZWave.seq_number()} | {:status, status()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :default_set_complete,
      command_byte: 0x07,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    status = Command.param!(command, :status)
    <<Command.param!(command, :seq_number), status_to_byte(status)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, status_byte>>) do
    case status_from_byte(status_byte) do
      {:ok, status} ->
        {:ok, [seq_number: seq_number, status: status]}

      {:error, _} ->
        {:error, %DecodeError{param: :status, value: status_byte, command: :default_set_complete}}
    end
  end

  @spec status_to_byte(status()) :: byte()
  def status_to_byte(:done), do: 0x06
  def status_to_byte(:busy), do: 0x07

  @spec status_from_byte(byte()) :: {:ok, status()} | {:error, :unknown_status}
  def status_from_byte(0x06), do: {:ok, :done}
  def status_from_byte(0x07), do: {:ok, :busy}
  def status_from_byte(_byte), do: {:error, :unknown_status}
end
