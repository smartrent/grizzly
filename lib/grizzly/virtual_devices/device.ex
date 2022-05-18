defmodule Grizzly.VirtualDevices.Device do
  @moduledoc """
  Behaviour for implementing virtual device specifics
  """

  alias Grizzly.ZWave.{Command, DeviceClass}

  @typedoc """
  A module that implements this behaviour
  """
  @type t() :: module()

  @doc """
  Initialize the device
  """
  @callback init(args :: term()) :: {:ok, state :: term(), DeviceClass.t()} | {:error, term()}

  @doc """
  Handle a Z-Wave command

  When handling a command you can reply, notify, or do nothing.

  In Z-Wave if your device does not understand the command sent it ignores the
  command. For this case you'd return `{:noreply, state}`.

  When a command is received and you want to reply back to the sender, this is
  when you will use `:reply`. Normally for a "get" kinda of command you will
  reply back with a "report" command within that same command class. When a
  "set" kind of command comes in your will respond with `:ack_response`

  Often times, if your device reports changes that have been made due to
  handling a command, you can return `:notify`. This happens is "set" operations
  and the appropriate `:ack_response` will be sent to the issuer of the "set"
  command for you.
  """
  @callback handle_command(Command.t(), state :: term()) ::
              {:reply, Command.t() | :ack_response, state :: term()}
              | {:noreply, state :: term()}
              | {:notify, Command.t(), state :: term()}

  @doc """
  Handle messages outside of the direct Z-Wave command processing

  An example is if you implement a multilevel sensor for a temperature sensor
  you could use this callback to handle messages from the sensor and notify the
  Z-Wave network about the change in temperature reading.any()

  ```elixir
  def init() do
    current_temp = read_temp()
    listen_to_temperature_changes()

    {:ok, %{temp: current_temp}}
  end

  def handle_info({:temp, new_temp}, state) do
    if state.current_temp == new_temp do
      {:noreply, state}
    else
      {:ok, report} = Grizzly.ZWave.Commands.MultiLevelSensorReport.new(
        sensor_type: :temperature,
        scale: 1,
        value: new_temp
      )
      {:notify, report, %{state | temp: new_temp}}
  end
  ```
  """
  @callback handle_info(msg :: term(), state :: term()) ::
              {:noreply, state :: term()} | {:notify, Command.t(), state :: term()}

  @optional_callbacks handle_info: 2
end
