defmodule Grizzly.VirtualDevices.TemperatureSensor do
  @moduledoc """
  A virtual device for a temperature sensor

  This virtual device reports changes in the sensor every minute using the
  `Grizzly.ZWave.Commands.SensorMultilevelReport` command.

  If you want a faster or slower reporting interval you can configure the
  `:report_interval` option.
  """
  @behaviour Grizzly.VirtualDevices.Device

  alias Grizzly.ZWave.{Command, DeviceClass}

  alias Grizzly.ZWave.Commands.{
    BasicReport,
    SensorMultilevelSupportedSensorReport,
    SensorMultilevelReport
  }

  @typedoc """
  Init options

  * `:report_interval` - the time in milliseconds to read and maybe report temp
    changes, default `60_000`
  * `:force_report` - report all temperature readings, default false (will only
    report if the temperature changed from last reading)
  """
  @type opt() :: {:report_interval, non_neg_integer()} | {:force_report, boolean()}

  @type state() :: %{temp: non_neg_integer(), force_report: boolean()}

  @impl Grizzly.VirtualDevices.Device
  @spec init([opt()]) :: {:ok, state(), DeviceClass.t()}
  def init(args) do
    report_interval = args[:report_interval] || 60_000
    force_report = args[:force_report] || false

    _ = :timer.send_interval(report_interval, :send_temp)
    {:ok, %{temp: 0, force_report: force_report}, DeviceClass.multilevel_sensor()}
  end

  @impl Grizzly.VirtualDevices.Device
  def handle_command(%Command{name: :basic_get}, state) do
    {:ok, report} = BasicReport.new(value: state.temp)

    {:reply, report, state}
  end

  def handle_command(%Command{name: :sensor_multilevel_get}, state) do
    {:reply, build_multilevel_sensor_report(state.temp), state}
  end

  def handle_command(%Command{name: :sensor_multilevel_supported_sensor_get}, state) do
    {:ok, report} = SensorMultilevelSupportedSensorReport.new(sensor_types: [:temperature])

    {:reply, report, state}
  end

  def handle_command(_, state) do
    {:noreply, state}
  end

  defp build_multilevel_sensor_report(value) do
    # According to the sensor multilevel command class if any scale or sensor
    # type requested is not supported we are to respond with a default supported
    # type and/or scale. This virtual device only supports temperature and scale 1
    # so we will always report those.
    {:ok, report} = SensorMultilevelReport.new(sensor_type: :temperature, scale: 1, value: value)

    report
  end

  @impl Grizzly.VirtualDevices.Device
  def handle_info(:send_temp, state) do
    new_temp = read_temp(state)

    if !state.force_report && new_temp == state.temp do
      {:noreply, state}
    else
      {:notify, build_multilevel_sensor_report(new_temp), %{state | temp: new_temp}}
    end
  end

  # simulate reading a temperature sensor
  defp read_temp(state) do
    if Enum.random([true, false]) do
      Enum.random(0..99)
    else
      state.temp
    end
  end
end
