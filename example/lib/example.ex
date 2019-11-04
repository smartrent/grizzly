defmodule Example do
  @moduledoc """
  Little self contained examples for working with Z-Wave common devices.

  There are many more commands in Grizzly and Z-Wave then what is
  represented here, please see `Grizzly`'s documentation for more
  commands.

  Each device can implement the commands a little different so be
  sure to refer to the device's user manual for more details about
  how each command behaves for your particular device.
  """

  alias Grizzly.CommandClass.{
    # for working with on/off switches
    SwitchBinary,
    # for locking and unlocking door locks
    DoorLock,
    # for working with user codes on locks
    UserCode,
    # working with the thermostat setpoint
    ThermostatSetpoint
  }

  def turn_switch_on(switch_id) do
    with {:ok, switch} <- Grizzly.get_node(switch_id),
         {:ok, switch} <- Grizzly.Node.connect(switch),
         :ok <- Grizzly.send_command(switch, SwitchBinary.Set, value: :on) do
      :ok
    else
      error -> error
    end
  end

  def turn_switch_off(switch_id) do
    with {:ok, switch} <- Grizzly.get_node(switch_id),
         {:ok, switch} <- Grizzly.Node.connect(switch),
         {:ok, switch_state} <- Grizzly.send_command(switch, SwitchBinary.Get) do
      switch_state
    else
      error -> error
    end
  end

  def lock_lock(lock_id) do
    with {:ok, lock} <- Grizzly.get_node(lock_id),
         {:ok, lock} <- Grizzly.Node.connect(lock),
         :ok <- Grizzly.send_command(lock, DoorLock.OperationSet, mode: :secured) do
      :ok
    else
      error -> error
    end
  end

  def unlock_lock(lock_id) do
    with {:ok, lock} <- Grizzly.get_node(lock_id),
         {:ok, lock} <- Grizzly.Node.connect(lock),
         :ok <- Grizzly.send_command(lock, DoorLock.OperationSet, mode: :unsecured) do
      :ok
    else
      error -> error
    end
  end

  def set_user_code(node_id) do
    with {:ok, zw_node} <- Grizzly.get_node(node_id),
         {:ok, zw_node} <- Grizzly.Node.connect(zw_node),
         :ok <-
           Grizzly.send_command(zw_node, UserCode.Set,
             slot_id: 1,
             slot_status: :occupied,
             user_code: [1, 2, 3, 4, 5]
           ) do
      :ok
    else
      error -> error
    end
  end

  def reset_user_code(node_id) do
    with {:ok, zw_node} <- Grizzly.get_node(node_id),
         {:ok, zw_node} <- Grizzly.Node.connect(zw_node),
         :ok <-
           Grizzly.send_command(zw_node, UserCode.Set,
             slot_id: 1,
             slot_status: :available,
             user_code: [0, 0, 0, 0, 0]
           ) do
      :ok
    else
      error -> error
    end
  end

  def get_lock_state(lock_id) do
    with {:ok, lock} <- Grizzly.get_node(lock_id),
         {:ok, lock} <- Grizzly.Node.connect(lock),
         {:ok, lock_state} <- Grizzly.send_command(lock, DoorLock.OperationGet) do
      lock_state
    else
      error -> error
    end
  end

  def get_thermostat_heating_setpoint(thermostat_id) do
    with {:ok, thermostat} <- Grizzly.get_node(thermostat_id),
         {:ok, thermostat} <- Grizzly.Node.connect(thermostat),
         {:ok, heating_setpoint} <-
           Grizzly.send_command(thermostat, ThermostatSetpoint.Get, type: :heating) do
      heating_setpoint
    else
      error -> error
    end
  end

  def set_thermostat_heating_setpoint(thermostat_id) do
    with {:ok, thermostat} <- Grizzly.get_node(thermostat_id),
         {:ok, thermostat} <- Grizzly.Node.connect(thermostat),
         {:ok, heating_setpoint} <-
           Grizzly.send_command(thermostat, ThermostatSetpoint.Set, type: :heating, value: 78) do
      heating_setpoint
    else
      error -> error
    end
  end

  def get_thermostat_cooling_setpoint(thermostat_id) do
    with {:ok, thermostat} <- Grizzly.get_node(thermostat_id),
         {:ok, thermostat} <- Grizzly.Node.connect(thermostat),
         {:ok, cooling_setpoint} <-
           Grizzly.send_command(thermostat, ThermostatSetpoint.Get, type: :cooling) do
      cooling_setpoint
    else
      error -> error
    end
  end

  def set_thermostat_cooling_setpoint(thermostat_id) do
    with {:ok, thermostat} <- Grizzly.get_node(thermostat_id),
         {:ok, thermostat} <- Grizzly.Node.connect(thermostat),
         {:ok, cooling_setpoint} <-
           Grizzly.send_command(thermostat, ThermostatSetpoint.Set, type: :cooling, value: 76) do
      cooling_setpoint
    else
      error -> error
    end
  end
end
