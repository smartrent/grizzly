defmodule Grizzly.ZWave.Commands.SupervisionReport do
  @moduledoc """
  This command is used to advertise the status of one or more command process(es).

  Params:

    * `:more_status_updates` - used to advertise if more Supervision Reports follow for the actual Session ID (required)
    * `:session_id` - carries the same value as the Session ID field of the Supervision Get Command which
                      initiated this session (required)
    * `:status` - the current status of the command process, one of :no_support, :working, :fail or :success (required)
    * `:duration` - the time in seconds needed to complete the current operation (required)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Supervision
  alias Grizzly.ZWave.DecodeError

  @type more_status_updates() :: :last_report | :more_reports
  @type status() :: :no_support | :working | :fail | :success
  @type param() ::
          {:more_status_updates, more_status_updates}
          | {:status, status}
          | {:duration, :unknown | non_neg_integer()}
          | {:session_id, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :supervision_report,
      command_byte: 0x02,
      command_class: Supervision,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    more_status_updates_bit =
      Command.param!(command, :more_status_updates) |> encode_more_status_updates()

    status_byte = Command.param!(command, :status) |> encode_status()
    duration_byte = Command.param!(command, :duration) |> encode_duration()
    session_id = Command.param!(command, :session_id)

    <<more_status_updates_bit::1, 0x00::1, session_id::6, status_byte, duration_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<more_status_updates_byte::1, _::1, session_id::6, status_byte, duration_byte>>
      ) do
    with {:ok, more_status_updates} <- decode_more_status_updates(more_status_updates_byte),
         {:ok, status} <- decode_status(status_byte) do
      {:ok,
       [
         more_status_updates: more_status_updates,
         session_id: session_id,
         status: status,
         duration: decode_duration(duration_byte)
       ]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp encode_more_status_updates(:last_report), do: 0x00
  defp encode_more_status_updates(:more_reports), do: 0x01

  defp decode_more_status_updates(0x00), do: {:ok, :last_report}
  defp decode_more_status_updates(0x01), do: {:ok, :more_reports}

  defp decode_status(0x00), do: {:ok, :no_support}
  defp decode_status(0x01), do: {:ok, :working}
  defp decode_status(0x02), do: {:ok, :fail}
  defp decode_status(0xFF), do: {:ok, :success}

  defp decode_status(byte),
    do: {:error, %DecodeError{value: byte, param: :status, command: :supervision_report}}

  defp encode_status(:no_support), do: 0x00
  defp encode_status(:working), do: 0x01
  defp encode_status(:fail), do: 0x02
  defp encode_status(:success), do: 0xFF
end
