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
  alias Grizzly.ZWave.DecodeError

  @type status :: :done | :busy

  @type param :: {:seq_number, ZWave.seq_number()} | {:status, status()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    status = Command.param!(command, :status)
    <<Command.param!(command, :seq_number), status_to_byte(status)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, status_byte>>) do
    case status_from_byte(status_byte) do
      {:ok, status} ->
        {:ok, [seq_number: seq_number, status: status]}

      {:error, _} ->
        {:error, %DecodeError{param: :status, value: status_byte, command: :default_set_complete}}
    end
  end

  @spec status_to_byte(status()) :: 0x06 | 0x07
  defp status_to_byte(:done), do: 0x06
  defp status_to_byte(:busy), do: 0x07

  @spec status_from_byte(byte()) :: {:ok, status()} | {:error, :unknown_status}
  defp status_from_byte(0x06), do: {:ok, :done}
  defp status_from_byte(0x07), do: {:ok, :busy}
  defp status_from_byte(_byte), do: {:error, :unknown_status}
end
