defmodule Grizzly.ZWave.Commands.AlarmReport do
  @moduledoc """
  This command notifies the application of the alarm state

  Params:

    * `:type` - the specific alarm type being reported - this different for
      each application, see device user manual for more details (required)
    * `:level` - the level is device specific, see device user manual for more
      details (required)
    * `:zensor_net_node_id` - the Zensor net node, if the device is not
      based off of Zensor Net, then this field is `0` (v2, optional, default 0)
    * `:zwave_status` - if the device status is active or deactive (v2)
    * `:zwave_type` - part of `Grizzly.ZWave.Notifications` spec (v2)
    * `:zwave_event` - part of the `Grizzly.ZWave.Notifications` spec (v2)
    * `:event_parameters` - additional parameters for the event as keyword list, see user
      manual for more information (v2, optional, default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError, Notifications}
  alias Grizzly.ZWave.CommandClasses.Alarm

  @type param ::
          {:type, byte()}
          | {:level, byte()}
          | {:zensor_net_node_id, ZWave.node_id()}
          | {:zwave_status, byte()}
          | {:zwave_event, Notifications.event()}
          | {:zwave_type, Notifications.type()}
          | {:event_parameters, [byte()]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :alarm_report,
      command_byte: 0x05,
      command_class: Alarm,
      params: build_params(params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    if Command.param(command, :zensor_net_node_id, false) do
      encode_v2(command)
    else
      encode_v1(command)
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<type, level>>) do
    {:ok, [type: type, level: level]}
  end

  def decode_params(
        <<type, level, zensor_node_id, zwave_status, zwave_type_byte, zwave_event_byte,
          params_length, event_params::binary-size(params_length), _rest::binary>>
      ) do
    with {:ok, zwave_type} <- Notifications.type_from_byte(zwave_type_byte),
         {:ok, zwave_event} <- Notifications.event_from_byte(zwave_type, zwave_event_byte),
         {:ok, event_parameters} <-
           Notifications.decode_event_params(zwave_type, zwave_event, event_params) do
      {:ok,
       [
         type: type,
         level: level,
         zensor_net_node_id: zensor_node_id,
         zwave_status: zwave_status,
         zwave_type: zwave_type,
         zwave_event: zwave_event,
         event_parameters: event_parameters
       ]}
    else
      {:error, :invalid_type_byte} ->
        {:error, %DecodeError{value: zwave_type_byte, param: :zwave_type, command: :alarm_report}}

      {:error, :invalid_event_byte} ->
        {:error,
         %DecodeError{value: zwave_event_byte, param: :zwave_event, command: :alarm_report}}

      error ->
        error
    end
  end

  defp encode_v1(command) do
    type = Command.param!(command, :type)
    level = Command.param!(command, :level)

    <<type, level>>
  end

  defp encode_v2(command) do
    type = Command.param!(command, :type)
    level = Command.param!(command, :level)
    zensor_node_id = Command.param!(command, :zensor_net_node_id)
    zwave_status = Command.param!(command, :zwave_status)
    zwave_type = Command.param!(command, :zwave_type)
    zwave_event = Command.param!(command, :zwave_event)
    event_params = Command.param!(command, :event_parameters)

    encoded_event_params =
      Notifications.encode_event_params(zwave_type, zwave_event, event_params)

    params_length = byte_size(encoded_event_params)

    <<type, level, zensor_node_id, zwave_status, Notifications.type_to_byte(zwave_type),
      Notifications.event_to_byte(zwave_type, zwave_event),
      params_length>> <>
      encoded_event_params
  end

  # TODO - Actually translate into report commands
  # defp params_from_binary(<<0>>), do: []
  # defp params_from_binary(params_bin), do: :erlang.binary_to_list(params_bin)

  defp build_params(params) do
    if Keyword.has_key?(params, :zwave_type) do
      Keyword.merge([zensor_net_node_id: 0, event_parameters: []], params)
    else
      params
    end
  end
end
