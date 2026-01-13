defmodule Grizzly.ZWave.Commands.NetworkUpdateRequestStatus do
  @moduledoc """
  This command is used to indicate if the Network Update Request command execution has completed
  successfully or not.

  Params:

    * `:seq_number` - the sequence number of the update network request command (required)

    * `:status` - the status of the Network Update process (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:status, NetworkManagementBasicNode.network_update_request_status()}
  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)

    status_byte =
      Command.param!(command, :status)
      |> NetworkManagementBasicNode.network_update_request_status_to_byte()

    <<seq_number, status_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, status_byte>>) do
    with {:ok, status} <-
           NetworkManagementBasicNode.network_update_request_status_from_byte(status_byte) do
      {:ok, [seq_number: seq_number, status: status]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :network_update_request_status}}
    end
  end
end
