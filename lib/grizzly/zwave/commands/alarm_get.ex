defmodule Grizzly.ZWave.Commands.AlarmGet do
  @moduledoc """
  This command is used to get the value of an alarm.

  Params:

    * `:type` - v1 alarm type (required for v1 only)

    * `:zwave_type` - Z-Wave alarm/notification type (required for v2+)

    * `:zwave_event` - Z-Wave event/state (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param ::
          {:type, byte()}
          | {:zwave_type, Notifications.type()}
          | {:zwave_event, Notifications.event()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :alarm_get,
      command_byte: 0x04,
      command_class: Alarm,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type = Command.param(command, :type, 0x00)
    zwave_type = Command.param(command, :zwave_type)
    zwave_event = Command.param(command, :zwave_event)

    if zwave_type == nil do
      # Alarm v1
      <<type>>
    else
      zwave_type_byte = Notifications.type_to_byte(zwave_type)

      if zwave_event == nil do
        <<type, zwave_type_byte>>
      else
        zwave_event_byte = Notifications.event_to_byte(zwave_type, zwave_event)
        <<type, zwave_type_byte, zwave_event_byte>>
      end
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<type>>), do: {:ok, [type: type]}

  def decode_params(<<type, zwave_type_byte>>) do
    with {:ok, zwave_type} <- Notifications.type_from_byte(zwave_type_byte) do
      {:ok, [type: type, zwave_type: zwave_type]}
    else
      {:error, :invalid_type_byte} ->
        {:error, %DecodeError{value: zwave_type_byte, param: :zwave_type, command: :alarm_get}}
    end
  end

  def decode_params(<<type, zwave_type_byte, zwave_event_byte>>) do
    with {:ok, zwave_type} <- Notifications.type_from_byte(zwave_type_byte),
         {:ok, zwave_event} <- Notifications.event_from_byte(zwave_type, zwave_event_byte) do
      {:ok, [type: type, zwave_type: zwave_type, zwave_event: zwave_event]}
    else
      {:error, :invalid_type_byte} ->
        {:error, %DecodeError{value: zwave_type_byte, param: :zwave_type, command: :alarm_get}}

      {:error, :invalid_event_byte} ->
        {:error, %DecodeError{value: zwave_event_byte, param: :zwave_event, command: :alarm_get}}
    end
  end
end
