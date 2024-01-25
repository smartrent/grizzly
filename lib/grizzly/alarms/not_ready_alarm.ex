defmodule Grizzly.Alarms.NotReadyAlarm do
  @moduledoc """
  Alarm that will be raised when the ReadyChecker init/1 function is called.
  It will be cleared when the ready/1 function is called.
  """

  @spec raise_alarm() :: :ok
  def raise_alarm() do
    if is_alarm_handler_alive?() do
      :alarm_handler.set_alarm(__MODULE__)
    end

    :ok
  end

  @spec clear_alarm() :: :ok
  def clear_alarm() do
    if is_alarm_handler_alive?() do
      :alarm_handler.clear_alarm(__MODULE__)
    end

    :ok
  end

  defp is_alarm_handler_alive?(), do: is_pid(Process.whereis(:alarm_handler))
end
