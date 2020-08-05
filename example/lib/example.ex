defmodule Example do
  alias Grizzly.Report
  alias Grizzly.ZWave.Command

  def turn_switch_on(switch_id) do
    Grizzly.send_command(switch_id, :switch_binary_set, target_value: :on)
  end

  def turn_switch_off(switch_id) do
    Grizzly.send_command(switch_id, :switch_binary_set, target_value: :off)
  end

  def get_switch_state(switch_id) do
    case Grizzly.send_command(switch_id, :switch_binary_get) do
      {:ok, %Report{status: :complete, type: :command, command: command}} ->
        {:ok, Command.param!(command, :target_value)}
    end
  end

  def lock_lock(lock_id) do
    Grizzly.send_command(lock_id, :door_lock_operation_set, mode: :unsecured)
  end

  def unlock_lock(lock_id) do
    Grizzly.send_command(lock_id, :door_lock_operation_get, mode: :secured)
  end

  # user code is a 4 - 10 digit string: "1234"
  def set_user_code(lock_id, slot_id, user_code) do
    params = [
      user_id: slot_id,
      user_id_status: :occupied,
      user_code: user_code
    ]

    Grizzly.send_command(lock_id, :user_code_set, params)
  end

  def reset_user_code(lock_id, slot_id) do
    params = [
      user_id: slot_id,
      user_id_status: :available,
      user_code: "0000"
    ]

    Grizzly.send_command(lock_id, :user_code_set, params)
  end

  def get_lock_state(lock_id) do
    case Grizzly.send_command(lock_id, :dor_lock_operation_get) do
      {:ok, %Report{status: :complete, type: :command, command: command}} ->
        {:ok, Command.param!(command, :mode)}
    end
  end

  def get_thermostat_heating_setpoint(thermostat_id) do
    case Grizzly.send_command(thermostat_id, :thermostat_setpoint_get, type: :heating) do
      {:ok, %Report{status: :complete, type: :command, command: command}} ->
        {:ok, Command.param!(command, :value)}
    end
  end

  def set_thermostat_heating_setpoint(thermostat_id) do
    params = [
      type: :heating,
      scale: :fahrenheit,
      value: 78
    ]

    :ok = Grizzly.send_command(thermostat_id, :thermostat_setpoint_set, params)
  end

  def get_thermostat_cooling_setpoint(thermostat_id) do
    case Grizzly.send_command(thermostat_id, :thermostat_setpoint_get, type: :cooling) do
      {:ok, %Report{status: :complete, type: :command, command: command}} ->
        {:ok, Command.param(command, :value)}
    end
  end

  def set_thermostat_cooling_setpoint(thermostat_id) do
    params = [
      type: :cooling,
      scale: :fahrenheit,
      value: 76
    ]

    :ok = Grizzly.send_command(thermostat_id, :thermostat_setpoint_set, params)
  end
end
