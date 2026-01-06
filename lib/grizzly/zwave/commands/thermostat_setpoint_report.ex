defmodule Grizzly.ZWave.Commands.ThermostatSetpointReport do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_REPORT of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to advertise the target value for a given
  setpoint type.

  Params:

    * `:type` - the setpoint type (required)
    * `:scale` - the setpoint scale (required)
    * `:value` - the value of the setpoint (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @impl Command
  @spec new([ThermostatSetpoint.param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_report,
      command_byte: 0x03,
      command_class: ThermostatSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Command
  def encode_params(command) do
    type = Command.param!(command, :type)
    scale_byte = Command.param!(command, :scale) |> ThermostatSetpoint.encode_scale()
    value = get_value(command, type)

    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<0x00::4, ThermostatSetpoint.encode_type(type)::size(4), precision::3, scale_byte::2,
      byte_size::3, int_value::signed-size(byte_size)-unit(8)>>
  end

  # The spec says when encoding `:na` type to force the size to 1 and the value to 0
  #
  #  "If this field [type] is set to 0x00 (N/A), it is RECOMMENDED to set the
  #   Size field to 1 and the Value field to 0."
  defp get_value(_command, :na), do: 0
  defp get_value(command, _other), do: Command.param!(command, :value)

  @impl Command
  def decode_params(
        <<_::4, type_byte::4, precision::3, scale_byte::2, byte_size::3,
          int_value::signed-size(byte_size)-unit(8), _::binary>>
        # trailing binary to capture extra 0 sent by the Aidoo
      ) do
    type = ThermostatSetpoint.decode_type(type_byte)

    case ThermostatSetpoint.decode_scale(scale_byte) do
      {:ok, scale} ->
        value = Encoding.decode_zwave_float(int_value, precision)
        {:ok, [type: type, scale: scale, value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
