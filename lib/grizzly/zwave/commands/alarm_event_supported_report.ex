defmodule Grizzly.ZWave.Commands.AlarmEventSupportedReport do
  @moduledoc """
  This command is used to advertise supported events/states for a specified
  Notification Type.

  Params:

    * `:type` - a Notification type
    * `:events` - the Notification events supported for that type
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param :: {:type, atom()} | {:events, [atom()]}

  @impl true
  def new(params) do
    command = %Command{
      name: :alarm_event_supported_report,
      command_byte: 0x02,
      command_class: Alarm,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    type = Command.param!(command, :type)
    events = Command.param!(command, :events)
    bitmasks = Notifications.encode_type_events(type, events)
    type_byte = Notifications.type_to_byte(type)
    <<type_byte, 0x00::size(3), byte_size(bitmasks)::size(5)>> <> bitmasks
  end

  @impl true
  def decode_params(
        <<type_byte, 0x00::size(3), number_of_masks::size(5),
          bitmasks::size(number_of_masks)-binary>>
      ) do
    with {:ok, type} <- Notifications.type_from_byte(type_byte),
         {:ok, events} <- Notifications.decode_type_events(type, bitmasks) do
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
end
