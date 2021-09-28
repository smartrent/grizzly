defmodule Grizzly.ZWave.Commands.AlarmEventSupportedGet do
  @moduledoc """
  This command is used to request the supported Notifications for a specified
  Notification Type.

  Params:

    * `:type` - a type of notification
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param :: {:type, atom()}

  @impl true
  def new(params) do
    command = %Command{
      name: :alarm_event_supported_get,
      command_byte: 0x01,
      command_class: Alarm,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type = Command.param!(command, :type)
    type_byte = Notifications.type_to_byte(type)
    <<type_byte>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<type_byte>>) do
    with {:ok, type} <- Notifications.type_from_byte(type_byte) do
      {:ok, [type: type]}
    else
      {:error, :invalid_type_byte} ->
        {:error,
         %DecodeError{value: type_byte, param: :type, command: :alarm_event_supported_get}}
    end
  end
end
