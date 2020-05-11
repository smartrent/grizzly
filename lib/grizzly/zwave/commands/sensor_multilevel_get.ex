defmodule Grizzly.ZWave.Commands.SensorMultilevelGet do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_GET of command class COMMAND_CLASS_SENSOR_MULTILEVEL.
  The command is used to request the current reading from a multilevel sensor.

  Params: * `:sensor_type` - `one of :temperature or :illuminance or :power or :humidity` etc.(v5)
          * `:scale` - ` 0..3 - identifies a unit of measurement` (v5)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  # See Grizzly.ZWave.CommandClasses.SensorMultilevel for the full list of possible sensor types
  @type sensor_type :: atom
  @type param :: {:sensor_type, sensor_type} | {:scale, 0..3}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_multilevel_get,
      command_byte: 0x04,
      command_class: SensorMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    case Command.param(command, :sensor_type) do
      nil ->
        <<>>

      sensor_type ->
        scale = Command.param!(command, :scale)
        sensor_type_byte = SensorMultilevel.encode_sensor_type(sensor_type)
        <<sensor_type_byte, 0x00::size(3), scale::size(2), 0x00::size(3)>>
    end
  end

  @impl true
  # v1 - v4
  def decode_params(<<>>) do
    {:ok, []}
  end

  # v5
  def decode_params(<<sensor_type_byte, _::size(3), scale::size(2), _::size(3)>>) do
    with {:ok, sensor_type} <- SensorMultilevel.decode_sensor_type(sensor_type_byte) do
      {:ok, [sensor_type: sensor_type, scale: scale]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
