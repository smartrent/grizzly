defmodule Grizzly.ZWave.Commands.NodeNeighborUpdateStatus do
  @moduledoc """
  This command is used to report the status of a node neighbor update operation.

  Params:

    * `:seq_number` - the sequence number of the node neighbor update request command (required)
    * `:status` - the status of the node neighbor update process (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type status :: :done | :failed

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:status, status()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    status = status_to_byte(Command.param!(command, :status))

    <<seq_number, status>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, status_byte>>) do
    status = status_from_byte(status_byte)

    {:ok, [seq_number: seq_number, status: status]}
  end

  defp status_to_byte(:done), do: 0x22
  defp status_to_byte(:failed), do: 0x23

  defp status_from_byte(0x22), do: :done
  defp status_from_byte(0x23), do: :failed
end
