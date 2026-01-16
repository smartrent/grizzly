defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedReport do
  @moduledoc """
  This command is used to report the thermostat's supported setpoint types.

  Params:

    * `:setpoint_types` - A list of supported setpoint types. See `t:Grizzly.ZWave.CommandClasses.ThermostatSetpoint.type/0`.

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param :: {:setpoint_types, [{ThermostatSetpoint.type(), boolean()}]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    setpoint_types = Command.param!(command, :setpoint_types)

    setpoint_types
    |> Enum.map(&setpoint_type_to_bitmask_index/1)
    |> encode_bitmask(min_bytes: 2)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(spec, <<first_bitmask>>),
    do: decode_params(spec, <<first_bitmask, 0x0>>)

  def decode_params(_spec, binary) do
    setpoint_types =
      binary
      |> decode_bitmask()
      |> Enum.map(&bitmask_index_to_setpoint_type/1)
      |> Enum.reject(&is_nil/1)

    {:ok, [setpoint_types: setpoint_types]}
  end

  defp setpoint_type_to_bitmask_index(:heating), do: 1
  defp setpoint_type_to_bitmask_index(:cooling), do: 2
  defp setpoint_type_to_bitmask_index(:furnace), do: 3
  defp setpoint_type_to_bitmask_index(:dry_air), do: 4
  defp setpoint_type_to_bitmask_index(:moist_air), do: 5
  defp setpoint_type_to_bitmask_index(:auto_changeover), do: 6
  defp setpoint_type_to_bitmask_index(:energy_save_heating), do: 7
  defp setpoint_type_to_bitmask_index(:energy_save_cooling), do: 8
  defp setpoint_type_to_bitmask_index(:away_heating), do: 9
  defp setpoint_type_to_bitmask_index(:away_cooling), do: 10
  defp setpoint_type_to_bitmask_index(:full_power), do: 11

  defp bitmask_index_to_setpoint_type(1), do: :heating
  defp bitmask_index_to_setpoint_type(2), do: :cooling
  defp bitmask_index_to_setpoint_type(3), do: :furnace
  defp bitmask_index_to_setpoint_type(4), do: :dry_air
  defp bitmask_index_to_setpoint_type(5), do: :moist_air
  defp bitmask_index_to_setpoint_type(6), do: :auto_changeover
  defp bitmask_index_to_setpoint_type(7), do: :energy_save_heating
  defp bitmask_index_to_setpoint_type(8), do: :energy_save_cooling
  defp bitmask_index_to_setpoint_type(9), do: :away_heating
  defp bitmask_index_to_setpoint_type(10), do: :away_cooling
  defp bitmask_index_to_setpoint_type(11), do: :full_power
  defp bitmask_index_to_setpoint_type(_), do: nil
end
