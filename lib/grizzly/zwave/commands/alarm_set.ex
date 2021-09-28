defmodule Grizzly.ZWave.Commands.AlarmSet do
  @moduledoc """
  This command is used to enable or disable the unsolicited transmission of a
  specific Notification/Alarm Type.

  Params:

    * `:zwave_type` - the type of alarm, e.g. :home_security
    * `:status` - the status of the alarm, either :enabled or :disabled
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param :: {:zwave_type, Notifications.type()} | {:status, Notifications.status()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :alarm_set,
      command_byte: 0x06,
      command_class: Alarm,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    zwave_type = Command.param!(command, :zwave_type)
    status = Command.param!(command, :status)
    zwave_type_byte = Notifications.type_to_byte(zwave_type)
    status_byte = Notifications.status_to_byte(status)
    <<zwave_type_byte, status_byte>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<zwave_type_byte, status_byte>>) do
    with {:ok, zwave_type} <- Notifications.type_from_byte(zwave_type_byte),
         {:ok, status} <- Notifications.status_from_byte(status_byte) do
      {:ok, [zwave_type: zwave_type, status: status]}
    else
      {:error, :invalid_type_byte} ->
        {:error, %DecodeError{value: zwave_type_byte, param: :zwave_type, command: :alarm_set}}

      {:error, :invalid_status_byte} ->
        {:error, %DecodeError{value: status_byte, param: :status, command: :alarm_set}}
    end
  end
end
