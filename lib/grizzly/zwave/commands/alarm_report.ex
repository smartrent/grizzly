defmodule Grizzly.ZWave.Commands.AlarmReport do
  @moduledoc """
  This command notifies the application of the alarm state (v1, v2) or the
  notification state (v8).

  Params:

    * `:type` - the specific alarm type being reported - this different for
      each application, see device user manual for more details (required)
    * `:level` - the level is device specific, see device user manual for more
      details (required)
    * `:zensor_net_node_id` - the Zensor net node, if the device is not
     based off of Zensor Net, then this field is `0` (v2, optional, default 0)
    * `:zwave_status` - if the device alarm status is :enabled or :disabled (v2)
    * `:zwave_type` - part of `Grizzly.ZWave.Notifications` spec (v2)
    * `:zwave_event` - part of the `Grizzly.ZWave.Notifications` spec (v2)
    * `:event_parameters` - additional parameters for the event as keyword list,
      see user manual for more information (v2+, optional, default `[]`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Alarm
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Notifications

  @type param ::
          {:type, byte()}
          | {:level, byte()}
          | {:zensor_net_node_id, ZWave.node_id()}
          | {:zwave_status, Notifications.status()}
          | {:zwave_event, Notifications.event()}
          | {:zwave_type, Notifications.type()}
          | {:sequence_number, byte()}
          | {:event_parameters, [byte()]}

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    cond do
      Command.param(command, :sequence_number) != nil ->
        encode_v8(command)

      Command.param(command, :zensor_net_node_id) != nil ->
        encode_v2(command)

      true ->
        encode_v1(command)
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<type, level>>) do
    {:ok, [type: type, level: level]}
  end

  def decode_params(<<
        type,
        level,
        zensor_node_id,
        status_byte,
        zwave_type_byte,
        zwave_event_byte,
        0x00::1,
        0x00::2,
        params_length::5,
        event_params::binary-size(params_length),
        # Sometimes a 0 seq_number is added
        _::binary
      >>) do
    zwave_type = type_from_byte(zwave_type_byte)
    zwave_event = event_from_byte(zwave_type, zwave_event_byte)

    with {:ok, zwave_status} <- Notifications.status_from_byte(status_byte),
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
    end
  end

  def decode_params(
        <<type, level, zensor_node_id, status_byte, zwave_type_byte, zwave_event_byte, 0x01::1,
          0x00::2, params_length::5, event_params::binary-size(params_length), sequence_number>>
      ) do
    zwave_type = type_from_byte(zwave_type_byte)
    zwave_event = event_from_byte(zwave_type, zwave_event_byte)

    with {:ok, zwave_status} <- Notifications.status_from_byte(status_byte),
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
         event_parameters: event_parameters,
         sequence_number: sequence_number
       ]}
    end
  end

  # Params sent by Schlage 468ZP
  def decode_params(
        <<type, level, zensor_node_id, status_byte, zwave_type_byte, zwave_event_byte>>
      ) do
    zwave_type = type_from_byte(zwave_type_byte)
    zwave_event = event_from_byte(zwave_type, zwave_event_byte)

    with {:ok, zwave_status} <- Notifications.status_from_byte(status_byte) do
      {:ok,
       [
         type: type,
         level: level,
         zensor_net_node_id: zensor_node_id,
         zwave_status: zwave_status,
         zwave_type: zwave_type,
         zwave_event: zwave_event,
         event_parameters: []
       ]}
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

    <<type, level, zensor_node_id, Notifications.status_to_byte(zwave_status),
      Notifications.type_to_byte(zwave_type),
      Notifications.event_to_byte(zwave_type, zwave_event), params_length>> <>
      encoded_event_params
  end

  defp encode_v8(command) do
    type = Command.param!(command, :type)
    level = Command.param!(command, :level)
    zwave_status = Command.param!(command, :zwave_status)
    zwave_type = Command.param!(command, :zwave_type)
    zwave_event = Command.param!(command, :zwave_event)
    sequence_number = Command.param!(command, :sequence_number)
    event_params = Command.param!(command, :event_parameters)

    encoded_event_params =
      Notifications.encode_event_params(zwave_type, zwave_event, event_params)

    params_length = byte_size(encoded_event_params)

    <<type, level, 0x00, Notifications.status_to_byte(zwave_status),
      Notifications.type_to_byte(zwave_type),
      Notifications.event_to_byte(zwave_type, zwave_event), 0x01::1, 0x00::2, params_length::5>> <>
      encoded_event_params <>
      <<sequence_number>>
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

  defp type_from_byte(byte) do
    case Notifications.type_from_byte(byte) do
      {:ok, type} -> type
      {:error, _} -> byte
    end
  end

  defp event_from_byte(type, byte) do
    case Notifications.event_from_byte(type, byte) do
      {:ok, event} -> event
      {:error, _} -> byte
    end
  end
end
