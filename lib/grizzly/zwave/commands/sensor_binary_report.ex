defmodule Grizzly.ZWave.Commands.SensorBinaryReport do
  @moduledoc """
  This command is used to advertise whether a binary sensor was triggered.

  Params:

    * `:triggered` - whether the sensor is triggered (required)

    * `:sensor_type` - the type of sensor (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SensorBinary

  @type param :: {:sensor_type, SensorBinary.sensor_type()} | {:triggered, boolean()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_binary_report,
      command_byte: 0x03,
      command_class: SensorBinary,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    triggered = Command.param!(command, :triggered)
    sensor_type = Command.param(command, :sensor_type)

    if sensor_type == nil do
      <<encode_triggered(triggered)>>
    else
      <<encode_triggered(triggered), SensorBinary.encode_type(sensor_type)>>
    end
  end

  @impl true
  def decode_params(<<triggered_byte, sensor_type_byte>>) do
    with {:ok, sensor_type} <- SensorBinary.decode_type(sensor_type_byte),
         {:ok, triggered} <- decode_triggered(triggered_byte) do
      {:ok, [triggered: triggered, sensor_type: sensor_type]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end

  def decode_params(<<triggered_byte>>) do
    with {:ok, triggered} <- decode_triggered(triggered_byte) do
      {:ok, [triggered: triggered]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp encode_triggered(true), do: 0xFF
  defp encode_triggered(false), do: 0x00

  defp decode_triggered(0x00), do: {:ok, false}
  defp decode_triggered(0xFF), do: {:ok, true}

  defp decode_triggered(byte),
    do: {:error, %DecodeError{value: byte, param: :triggered, command: :sensor_binary_report}}
end
