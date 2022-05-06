defmodule Grizzly.VirtualDevices.Thermostat do
  @moduledoc """
  Implementation of a virtual device for a thermostat
  """

  @behaviour Grizzly.VirtualDevices.Device

  alias Grizzly.ZWave.DeviceClass

  @impl Grizzly.VirtualDevices.Device
  def init(), do: {:ok, %{}, DeviceClass.thermostat_hvac()}

  @impl Grizzly.VirtualDevices.Device
  def handle_command(_command, state) do
    {:ok,
     %Grizzly.ZWave.Command{
       name: :name,
       command_class: __MODULE__,
       command_byte: 12,
       impl: __MODULE__
     }, state}
  end
end
