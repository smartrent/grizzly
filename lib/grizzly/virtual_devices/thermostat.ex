defmodule Grizzly.VirtualDevices.Thermostat do
  @moduledoc """
  Implementation of a virtual device for a thermostat
  """

  use GenServer

  @behaviour Grizzly.VirtualDevices.Device

  alias Grizzly.VirtualDevices
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
  def device_spec(_device_opts) do
    DeviceClass.thermostat_hvac()
  end

  @doc """
  Start a thermostat device
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(opts) do
    id = VirtualDevices.add_device(__MODULE__, Keyword.merge(opts, server: self()))

    state = %{
      setpoints: %{
        heating: 22.0,
        cooling: 26.0
      },
      fan_mode: :auto_low,
      temperature: 24.0,
      mode: :cooling,
      basic: :on,
      scale: :celsius,
      device_id: id
    }

    {:ok, state}
  end

  @impl Grizzly.VirtualDevices.Device
  def handle_command(command, device_opts) do
    server = Keyword.fetch!(device_opts, :server)
    GenServer.call(server, {:handle_command, command})
  end

  @impl GenServer
  def handle_call(:get_device_id, _from, state) do
    {:ok, state.device_id, state}
  end

  def handle_call(
        {:handle_command, %Command{name: :thermostat_setpoint_get} = command},
        _from,
        state
      ) do
    type = Command.param!(command, :type)

    case Map.get(state.setpoints, type) do
      nil ->
        {:reply, {:error, :timeout}, state}

      value ->
        response = ThermostatSetpointReport.new(type: type, value: value, scale: state.scale)
        {:reply, response, state}
    end
  end

  def handle_call(
        {:handle_command, %Command{name: :thermostat_setpoint_set} = command},
        _from,
        state
      ) do
    scale = Command.param!(command, :scale)
    type = Command.param!(command, :type)

    value =
      command
      |> Command.param!(:value)
      |> maybe_convert_value(scale, state)

    case Map.get(state.setpoints, type) do
      nil ->
        {:reply, :ok, state}

      _old_value ->
        new_setpoints = Map.put(state.setpoints, type, value)
        {:reply, :ok, %{state | setpoints: new_setpoints}}
    end
  end

  def handle_call({:handle_command, %Command{name: :thermostat_fan_mode_get}}, _from, state) do
    response = ThermostatFanModeReport.new(mode: state.fan_mode)

    {:reply, response, state}
  end

  def handle_call(
        {:handle_command, %Command{name: :thermostat_fan_mode_set} = command},
        _from,
        state
      ) do
    mode = Command.param!(command, :mode)

    {:reply, :ok, %{state | fan_mode: mode}}
  end

  def handle_call({:handle_command, %Command{name: :sensor_multilevel_get}}, _from, state) do
    response =
      SensorMultilevelReport.new(sensor_type: :temperature, scale: 1, value: state.temperature)

    {:reply, response, state}
  end

  def handle_call({:handle_command, %Command{name: :thermostat_mode_get}}, _from, state) do
    response = ThermostatModeReport.new(mode: state.mode)
    {:reply, response, state}
  end

  def handle_call(
        {:handle_command, %Command{name: :thermostat_mode_set} = command},
        _from,
        state
      ) do
    new_mode = Command.param!(command, :mode)
    {:reply, :ok, %{state | mode: new_mode}}
  end

  def handle_call(
        {:handle_command, %Command{name: :sensor_multilevel_supported_sensor_get}},
        _from,
        state
      ) do
    response = SensorMultilevelSupportedSensorReport.new(sensor_types: [:temperature])
    {:reply, response, state}
  end

  def handle_call({:handle_command, %Command{name: :basic_get}}, _from, state) do
    response = BasicReport.new(value: state.basic)
    {:reply, response, state}
  end

  def handle_call({:handle_command, %Command{name: :basic_set} = command}, _from, state) do
    value = Command.param!(command, :value)
    {:reply, :ok, %{state | basic: value}}
  end

  def handle_call({:handle_command, _other}, state), do: {{:error, :timeout}, state}

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
