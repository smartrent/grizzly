defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedReport do
  @moduledoc """
  This command is used to report the thermostat's supported setpoint types.

  Params:

    * `:setpoint_types` - A list of supported setpoint types. See `t:Grizzly.ZWave.CommandClasses.ThermostatSetpoint.type/0`.

  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param :: {:setpoint_types, [{ThermostatSetpoint.type(), boolean()}]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_supported_report,
      command_byte: 0x05,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    setpoint_types = Command.param!(command, :setpoint_types)

    bit_masks =
      for byte_index <- 1..2 do
        for bit_index <- 7..0, into: <<>> do
          setpoint_type = bitmask_field_to_setpoint_type(byte_index, bit_index)

          if Keyword.get(setpoint_types, setpoint_type) == true,
            do: <<1::size(1)>>,
            else: <<0::size(1)>>
        end
      end

    for bit_mask <- bit_masks, into: <<>>, do: bit_mask
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<first_bitmask::size(8)>>),
    do: decode_params(<<first_bitmask, 0x0::size(8)>>)

  def decode_params(bitmasks) do
    bitmasks_as_indexed_list =
      :erlang.binary_to_list(bitmasks) |> Enum.take(2) |> Enum.with_index(1)

    setpoint_types =
      Enum.flat_map(bitmasks_as_indexed_list, fn {bitmask_byte, byte_index} ->
        for bit_index <- 0..7, into: [] do
          {bitmask_field_to_setpoint_type(byte_index, bit_index),
           (bitmask_byte &&& 1 <<< bit_index) !== 0}
        end
      end)
      |> Keyword.drop([nil])

    {:ok, [setpoint_types: setpoint_types]}
  end

  @spec bitmask_field_to_setpoint_type(pos_integer(), 0..7) ::
          ThermostatSetpoint.type() | :reserved | nil
  defp bitmask_field_to_setpoint_type(byte_index, bit_index)

  defp bitmask_field_to_setpoint_type(1, 1), do: :heating
  defp bitmask_field_to_setpoint_type(1, 2), do: :cooling
  defp bitmask_field_to_setpoint_type(1, 3), do: :furnace
  defp bitmask_field_to_setpoint_type(1, 4), do: :dry_air
  defp bitmask_field_to_setpoint_type(1, 5), do: :moist_air
  defp bitmask_field_to_setpoint_type(1, 6), do: :auto_changeover
  defp bitmask_field_to_setpoint_type(1, 7), do: :energy_save_heating
  defp bitmask_field_to_setpoint_type(2, 0), do: :energy_save_cooling
  defp bitmask_field_to_setpoint_type(2, 1), do: :away_heating
  defp bitmask_field_to_setpoint_type(2, 2), do: :away_cooling
  defp bitmask_field_to_setpoint_type(2, 3), do: :full_power
  defp bitmask_field_to_setpoint_type(_, _), do: nil
end
