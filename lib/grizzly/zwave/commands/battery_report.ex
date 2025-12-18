defmodule Grizzly.ZWave.Commands.BatteryReport do
  @moduledoc """
  This module implements the BATTERY_REPORT command of the COMMAND_CLASS_BATTERY
  command class.

  Params:

    * `:level` - percent charged - v1
    * `:charging_status` - whether charging, discharging or maintaining - v2
    * `:rechargeable` - whether the battery is rechargeable - v2
    * `:backup` - whether used as a backup source of power - v2
    * `:overheating` - whether it is overheating - v2
    * `:low_fluid` - whether the battery fluid is low and should be refilled - v2
    * `:replace_recharge` - whether the battery needs to be replaced or
      recharged - v2
    * `:disconnected` - whether the battery is disconnected nd the node is
      running on an alternative power source - v2
    * `:low_temperature` - whether the battery of a device has stopped charging
      due to low temperature - v3

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Battery
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:level, 0..100}
          | {:charging_status, :charging | :discharging | :maintaining}
          | {:rechargeable, boolean}
          | {:backup, boolean}
          | {:overheating, boolean}
          | {:low_fluid, boolean}
          | {:replace_recharge, :unknown | :soon | :now}
          | {:disconnected, boolean}
          | {:low_temperature, boolean}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :battery_report,
      command_byte: 0x03,
      command_class: Battery,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    level = encode_level(Command.param!(command, :level))
    charging_status = Command.param(command, :charging_status)

    if charging_status == nil do
      # v1
      <<level>>
    else
      charging_status_byte = encode_charging_status(charging_status)
      rechargeable_byte = encode_rechargeable(Command.param!(command, :rechargeable))
      backup_byte = encode_backup(Command.param!(command, :backup))
      overheating_byte = encode_overheating(Command.param!(command, :overheating))
      low_fluid_byte = encode_low_fluid(Command.param!(command, :low_fluid))
      replace_recharge_byte = encode_replace_recharge(Command.param!(command, :replace_recharge))
      disconnected_byte = encode_disconnected(Command.param!(command, :disconnected))
      low_temperature = Command.param(command, :low_temperature)

      if low_temperature == nil do
        # v2
        <<level, charging_status_byte::2, rechargeable_byte::1, backup_byte::1,
          overheating_byte::1, low_fluid_byte::1, replace_recharge_byte::2, 0x00::7,
          disconnected_byte::1>>
      else
        # v3
        low_temperature_byte = encode_low_temperature(low_temperature)

        <<level, charging_status_byte::2, rechargeable_byte::1, backup_byte::1,
          overheating_byte::1, low_fluid_byte::1, replace_recharge_byte::2, 0x00::6,
          low_temperature_byte::1, disconnected_byte::1>>
      end
    end
  end

  @impl Grizzly.ZWave.Command
  # v1
  def decode_params(<<level_byte>>) do
    case level_from_byte(level_byte) do
      {:ok, level} ->
        {:ok, [level: level]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  # v2-3
  def decode_params(
        <<level_byte, charging_status_byte::2, rechargeable_byte::1, backup_byte::1,
          overheating_byte::1, low_fluid_byte::1, replace_recharge_byte::2, _reserved::6,
          low_temperature_byte::1, disconnected_byte::1>>
      ) do
    with {:ok, level} <- level_from_byte(level_byte),
         {:ok, charging_status} <- charging_status_from_byte(charging_status_byte),
         {:ok, replace_recharge} <- replace_recharge_from_byte(replace_recharge_byte) do
      {:ok,
       [
         level: level,
         charging_status: charging_status,
         rechargeable: rechargeable_byte == 0x01,
         backup: backup_byte == 0x01,
         overheating: overheating_byte == 0x01,
         low_fluid: low_fluid_byte == 0x01,
         replace_recharge: replace_recharge,
         low_temperature: low_temperature_byte == 0x01,
         disconnected: disconnected_byte == 0x01
       ]}
    end
  end

  defp encode_level(level) when level in 0..100, do: level

  defp encode_charging_status(:discharging), do: 0x00
  defp encode_charging_status(:charging), do: 0x01
  defp encode_charging_status(:maintaining), do: 0x02

  defp encode_rechargeable(false), do: 0x00
  defp encode_rechargeable(true), do: 0x01

  defp encode_backup(false), do: 0x00
  defp encode_backup(true), do: 0x01

  defp encode_overheating(false), do: 0x00
  defp encode_overheating(true), do: 0x01

  defp encode_low_fluid(false), do: 0x00
  defp encode_low_fluid(true), do: 0x01

  defp encode_replace_recharge(:unknown), do: 0x00
  defp encode_replace_recharge(:soon), do: 0x01
  defp encode_replace_recharge(:now), do: 0x03

  defp encode_disconnected(false), do: 0x00
  defp encode_disconnected(true), do: 0x01

  defp encode_low_temperature(false), do: 0x00
  defp encode_low_temperature(true), do: 0x01

  # low battery warning
  defp level_from_byte(0xFF), do: {:ok, 0}
  defp level_from_byte(level_byte) when level_byte in 0..100, do: {:ok, level_byte}
  # some locks sometimes report a battery level of 101%... (:
  defp level_from_byte(level_byte) when level_byte > 100, do: {:ok, 100}

  defp level_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :level, command: :battery_report}}

  defp charging_status_from_byte(0x00), do: {:ok, :discharging}
  defp charging_status_from_byte(0x01), do: {:ok, :charging}
  defp charging_status_from_byte(0x02), do: {:ok, :maintaining}

  defp charging_status_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :charging_status, command: :battery_report}}

  # If bit 1 is set, bit 0 is _supposed_ to be set as well, but we'll allow either.
  # This function doesn't have an error fallback because Dialyzer knows that it can only be 0..3
  # since it's derived from a 2-bit value.
  defp replace_recharge_from_byte(0x03), do: {:ok, :now}
  defp replace_recharge_from_byte(0x02), do: {:ok, :now}
  defp replace_recharge_from_byte(0x01), do: {:ok, :soon}
  defp replace_recharge_from_byte(0x00), do: {:ok, :unknown}
end
