defmodule Grizzly.ZWave.Commands.AlarmEventSupportedReport do
  @moduledoc """
  This command is used to advertise supported events/states for a specified
  Notification Type.

  Params:

    * `:type` - a Notification type
    * `:events` - the Notification events supported for that type
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Alarm
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.Notifications

  @type param :: {:type, atom()} | {:events, [atom()]}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :alarm_event_supported_report,
      command_byte: 0x02,
      command_class: Alarm,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    type = Command.param!(command, :type)
    events = Command.param!(command, :events)
    bitmasks = encode_type_events(type, events)
    type_byte = Notifications.type_to_byte(type)
    <<type_byte, 0x00::3, byte_size(bitmasks)::size(5)>> <> bitmasks
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<type_byte, 0x00::3, number_of_masks::5, bitmasks::binary-size(number_of_masks)>>
      ) do
    with {:ok, type} <- Notifications.type_from_byte(type_byte),
         {:ok, events} <- decode_type_events(type, bitmasks) do
      {:ok, [type: type, events: events]}
    else
      {:error, :invalid_type_byte} ->
        {:error,
         %DecodeError{value: type_byte, param: :type, command: :alarm_event_supported_report}}

      {:error, :invalid_type_event} ->
        {:error,
         %DecodeError{value: bitmasks, param: :events, command: :alarm_event_supported_report}}
    end
  end

  @spec encode_type_events(atom, [atom]) :: binary
  defp encode_type_events(type, events) do
    events
    |> Enum.map(&Notifications.event_to_byte(type, &1))
    |> Encoding.encode_bitmask()
  end

  @spec decode_type_events(atom, binary) ::
          {:error, :invalid_type} | {:error, :invalid_type_event} | {:ok, [atom()]}
  defp decode_type_events(type, binary) do
    alarm_events =
      binary
      |> Encoding.decode_bitmask()
      |> Enum.map(fn byte ->
        case Notifications.event_from_byte(type, byte) do
          {:ok, event} -> event
          {:error, _} -> nil
        end
      end)

    if Enum.any?(alarm_events, &(&1 == nil)) do
      {:error, :invalid_type_event}
    else
      {:ok, alarm_events}
    end
  end
end
