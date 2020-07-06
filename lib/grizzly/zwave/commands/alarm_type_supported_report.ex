defmodule Grizzly.ZWave.Commands.AlarmTypeSupportedReport do
  @moduledoc """
  This command is used to advertise supported Alarm/Notification Types.
  Versions 2+ are supported.

  Params:

    * `:types` - the types of alarms supported by the device

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param :: {:types, [Notifications.type()]}

  @impl true
  def new(params) do
    command = %Command{
      name: :alarm_type_supported_report,
      command_byte: 0x08,
      command_class: Alarm,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    types = Command.param!(command, :types)
    bitmasks = Notifications.encode_alarm_types(types)
    <<0x00::size(3), byte_size(bitmasks)::size(5)>> <> bitmasks
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<0x00::size(3), number_of_masks::size(5), bitmasks::binary-size(number_of_masks)>>
      ) do
    with {:ok, types} <- Notifications.decode_alarm_types(bitmasks) do
      {:ok, [types: types]}
    else
      {:error, :invalid_type} ->
        {:error,
         %DecodeError{
           value: bitmasks,
           param: :types,
           command: :alarm_supported_types_report
         }}
    end
  end
end
