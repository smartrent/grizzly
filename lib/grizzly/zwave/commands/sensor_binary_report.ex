defmodule Grizzly.ZWave.Commands.SensorBinaryReport do
  @moduledoc """
  This command is used to advertise whether a binary sensor was triggered.

  Params:

    * `:triggered` - whether the sensor is triggered (required)

    * `:sensor_type` - the type of sensor (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.ZWEnum

  @type param :: {:sensor_type, atom()} | {:triggered, boolean()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    triggered = Command.param!(command, :triggered)
    sensor_type = Command.param(command, :sensor_type)

    if sensor_type == nil do
      <<encode_triggered(triggered)>>
    else
      <<encode_triggered(triggered), ZWEnum.fetch!(Encoding.binary_sensor_types(), sensor_type)>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<triggered_byte, sensor_type_byte>>) do
    with {:ok, sensor_type} <- ZWEnum.fetch_key(Encoding.binary_sensor_types(), sensor_type_byte),
         {:ok, triggered} <- decode_triggered(triggered_byte) do
      {:ok, [triggered: triggered, sensor_type: sensor_type]}
    else
      {:error, %DecodeError{} = error} ->
        error

      :error ->
        {:error, %DecodeError{value: sensor_type_byte, param: :sensor_type}}
    end
  end

  def decode_params(_spec, <<triggered_byte>>) do
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
