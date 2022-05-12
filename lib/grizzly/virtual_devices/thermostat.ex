defmodule Grizzly.VirtualDevices.Thermostat do
  @moduledoc """
  Implementation of a virtual device for a thermostat
  """

  @behaviour Grizzly.VirtualDevices.Device

  alias Grizzly.ZWave.{Command, DeviceClass}

  alias Grizzly.ZWave.Commands.{
    BasicReport,
    ThermostatSetpointReport,
    ThermostatModeReport,
    ThermostatFanModeReport,
    SensorMultilevelReport,
    SensorMultilevelSupportedSensorReport
  }

  @impl Grizzly.VirtualDevices.Device
  def init() do
    state = %{
      setpoints: %{
        heating: 22.0,
        cooling: 26.0
      },
      fan_mode: :auto_low,
      temperature: 24.0,
      mode: :cooling,
      basic: :on,
      scale: :celsius
    }

    {:ok, state, DeviceClass.thermostat_hvac()}
  end

  @impl Grizzly.VirtualDevices.Device
  def handle_command(%Command{name: :thermostat_setpoint_get} = command, state) do
    type = Command.param!(command, :type)

    case Map.get(state.setpoints, type) do
      nil ->
        {:noreply, state}

      value ->
        {:ok, report} = ThermostatSetpointReport.new(type: type, value: value, scale: state.scale)
        {:reply, report, state}
    end
  end

  def handle_command(%Command{name: :thermostat_setpoint_set} = command, state) do
    scale = Command.param!(command, :scale)
    type = Command.param!(command, :type)

    value =
      command
      |> Command.param!(:value)
      |> maybe_convert_value(scale, state)

    case Map.get(state.setpoints, type) do
      nil ->
        {:reply, :ack_response, state}

      _old_value ->
        new_setpoints = Map.put(state.setpoints, type, value)
        {:reply, :ack_response, %{state | setpoints: new_setpoints}}
    end
  end

  def handle_command(%Command{name: :thermostat_fan_mode_get}, state) do
    {:ok, report} = ThermostatFanModeReport.new(mode: state.fan_mode)

    {:reply, report, state}
  end

  def handle_command(%Command{name: :thermostat_fan_mode_set} = command, state) do
    mode = Command.param!(command, :mode)

    {:reply, :ack_response, %{state | fan_mode: mode}}
  end

  def handle_command(%Command{name: :sensor_multilevel_get}, state) do
    {:ok, report} =
      SensorMultilevelReport.new(sensor_type: :temperature, scale: 1, value: state.temperature)

    {:reply, report, state}
  end

  def handle_command(%Command{name: :thermostat_mode_get}, state) do
    {:ok, report} = ThermostatModeReport.new(mode: state.mode)
    {:reply, report, state}
  end

  def handle_command(%Command{name: :thermostat_mode_set} = command, state) do
    new_mode = Command.param!(command, :mode)
    {:reply, :ack_response, %{state | mode: new_mode}}
  end

  def handle_command(%Command{name: :sensor_multilevel_supported_sensor_get}, state) do
    {:ok, report} = SensorMultilevelSupportedSensorReport.new(sensor_types: [:temperature])
    {:reply, report, state}
  end

  def handle_command(%Command{name: :basic_get}, state) do
    {:ok, report} = BasicReport.new(value: state.basic)
    {:reply, report, state}
  end

  def handle_command(%Command{name: :basic_set} = command, state) do
    value = Command.param!(command, :value)
    {:reply, :ack_response, %{state | basic: value}}
  end

  defp maybe_convert_value(value, scale, state) do
    if state.scale == scale do
      value
    else
      convert_value(value, scale, state.scale)
    end
  end

  defp convert_value(value, :celsius, :fahrenheit) do
    celsius_to_fahrenheit(value)
  end

  defp convert_value(value, _fah, _cel) do
    fahrenheit_to_celsius(value)
  end

  defp celsius_to_fahrenheit(cel) do
    cel * 1.8 + 32
  end

  defp fahrenheit_to_celsius(fah) do
    (fah - 32) / 1.8
  end
end
