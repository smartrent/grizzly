defmodule Grizzly.ZWave.Commands.SupervisionGet do
  @moduledoc """
  This command is used to initiate the execution of a command and to request the immediate and future
  status of the process being initiated.

  Params:

    * `:status_updates` - used to allow a receiving node to advertise application status updates in future Supervision
                          Report Commands (required)
    * `:session_id` - used to detect redundant invocations due to retransmissions (required)
    * `:encapsulated_command` - an encapsulated command  (required) -see ZWave Transport Encapsulation Command Class Specifications

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Supervision

  @type status_updates :: :one_now | :one_now_more_later
  @type param ::
          {:status_updates, status_updates()}
          | {:session_id, byte}
          | {:encapsulated_command, binary}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :supervision_get,
      command_byte: 0x01,
      command_class: Supervision,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    status_updates_bit = Command.param!(command, :status_updates) |> encode_status_updates()

    session_id = Command.param!(command, :session_id)
    encapsulated_command = Command.param!(command, :encapsulated_command)
    encapsulated_command_length = byte_size(encapsulated_command)

    <<status_updates_bit::size(1), 0x00::size(1), session_id::size(6),
      encapsulated_command_length>> <> encapsulated_command
  end

  @impl true
  def decode_params(
        <<status_updates_bit::size(1), 0x00::size(1), session_id::size(6), length,
          encapsulated_command::size(length)-unit(8)-binary>>
      ) do
    {:ok, status_updates} = decode_status_updates(status_updates_bit)

    {:ok,
     [
       status_updates: status_updates,
       session_id: session_id,
       encapsulated_command: encapsulated_command
     ]}
  end

  defp encode_status_updates(:one_now), do: 0x00
  defp encode_status_updates(:one_now_more_later), do: 0x01

  defp decode_status_updates(0x00), do: {:ok, :one_now}
  defp decode_status_updates(0x01), do: {:ok, :one_now_more_later}
end
