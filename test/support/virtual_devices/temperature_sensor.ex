defmodule Grizzly.VirtualDevices.TemperatureSensor do
  @moduledoc false

  @behaviour Grizzly.VirtualDevices.Device

  use GenServer

  alias Grizzly.VirtualDevices
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DeviceClass

  @typedoc """
  Init options

  * `:report_interval` - the time in milliseconds to read and maybe report temp
    changes, default `60_000`
  * `:force_report` - report all temperature readings, default false (will only
    report if the temperature changed from last reading)
  """
  @type opt() :: {:report_interval, non_neg_integer()} | {:force_report, boolean()}

  @type state() :: %{
          temp: non_neg_integer(),
          force_report: boolean(),
          device_id: Grizzly.VirtualDevices.id()
        }

  @impl Grizzly.VirtualDevices.Device
  def device_spec(_device_opts) do
    DeviceClass.multilevel_sensor()
  end

  @doc """
  Start the temperature sensor
  """
  @spec start_link([opt()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    report_interval = opts[:report_interval] || 60_000
    force_report = opts[:force_report] || false

    _ = :timer.send_interval(report_interval, :send_temp)
    {:ok, %{temp: 0, force_report: force_report, device_id: nil}}
  end

  @impl Grizzly.VirtualDevices.Device
  def set_device_id(server, device_id) do
    GenServer.cast(server, {:set_device_id, device_id})
  end

  @impl Grizzly.VirtualDevices.Device
  def handle_command(command, device_opts) do
    server = Keyword.fetch!(device_opts, :server)

    GenServer.call(server, {:handle_command, command})
  end

  @impl GenServer
  def handle_cast({:set_device_id, device_id}, state) do
    {:noreply, %{state | device_id: device_id}}
  end

  @impl GenServer
  def handle_info(:send_temp, state) do
    new_temp = read_temp(state)

    if state.device_id == nil or (!state.force_report && new_temp == state.temp) do
      {:noreply, state}
    else
      {:ok, command} = build_multilevel_sensor_report(new_temp)
      VirtualDevices.broadcast_command(state.device_id, command)

      {:noreply, %{state | temp: new_temp}}
    end
  end

  @impl GenServer
  def handle_call({:handle_command, %Command{name: :basic_get}}, _from, state) do
    report = Commands.create(:basic_report, value: state.temp)

    {:reply, report, state}
  end

  def handle_call({:handle_command, %Command{name: :sensor_multilevel_get}}, _from, state) do
    {:reply, build_multilevel_sensor_report(state.temp), state}
  end

  def handle_call(
        {:handle_command, %Command{name: :sensor_multilevel_supported_sensor_get}},
        _from,
        state
      ) do
    result =
      Commands.create(:sensor_multilevel_supported_sensor_report, sensor_types: [:temperature])

    {:reply, result, state}
  end

  def handle_call({:handle_command, _unsupported_command}, _from, state) do
    {:reply, {:error, :timeout}, state}
  end

  defp build_multilevel_sensor_report(value) do
    # According to the sensor multilevel command class if any scale or sensor
    # type requested is not supported we are to respond with a default supported
    # type and/or scale. This virtual device only supports temperature and scale 1
    # so we will always report those.
    Commands.create(:sensor_multilevel_report, sensor_type: :temperature, scale: 1, value: value)
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
