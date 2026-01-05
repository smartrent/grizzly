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
  alias Grizzly.ZWave.DecodeError

  @type param :: {:setpoint_types, [{ThermostatSetpoint.type(), boolean()}]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_supported_report,
      command_byte: 0x05,
      command_class: ThermostatSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    setpoint_types = Command.param!(command, :setpoint_types)

    setpoint_types
    |> Enum.map(&setpoint_type_to_bitmask_index/1)
    |> encode_bitmask(min_bytes: 2)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<first_bitmask>>),
    do: decode_params(<<first_bitmask, 0x0>>)

  def decode_params(binary) do
    setpoint_types =
      binary
      |> decode_bitmask()
      |> Enum.map(&bitmask_index_to_setpoint_type/1)
      |> Enum.reject(&is_nil/1)

    {:ok, [setpoint_types: setpoint_types]}
  end

  def setpoint_type_to_bitmask_index(:heating), do: 1
  def setpoint_type_to_bitmask_index(:cooling), do: 2
  def setpoint_type_to_bitmask_index(:furnace), do: 3
  def setpoint_type_to_bitmask_index(:dry_air), do: 4
  def setpoint_type_to_bitmask_index(:moist_air), do: 5
  def setpoint_type_to_bitmask_index(:auto_changeover), do: 6
  def setpoint_type_to_bitmask_index(:energy_save_heating), do: 7
  def setpoint_type_to_bitmask_index(:energy_save_cooling), do: 8
  def setpoint_type_to_bitmask_index(:away_heating), do: 9
  def setpoint_type_to_bitmask_index(:away_cooling), do: 10
  def setpoint_type_to_bitmask_index(:full_power), do: 11

  def bitmask_index_to_setpoint_type(1), do: :heating
  def bitmask_index_to_setpoint_type(2), do: :cooling
  def bitmask_index_to_setpoint_type(3), do: :furnace
  def bitmask_index_to_setpoint_type(4), do: :dry_air
  def bitmask_index_to_setpoint_type(5), do: :moist_air
  def bitmask_index_to_setpoint_type(6), do: :auto_changeover
  def bitmask_index_to_setpoint_type(7), do: :energy_save_heating
  def bitmask_index_to_setpoint_type(8), do: :energy_save_cooling
  def bitmask_index_to_setpoint_type(9), do: :away_heating
  def bitmask_index_to_setpoint_type(10), do: :away_cooling
  def bitmask_index_to_setpoint_type(11), do: :full_power
  def bitmask_index_to_setpoint_type(_), do: nil
end
