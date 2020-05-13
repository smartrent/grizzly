defmodule Grizzly.ZWave.Commands.ThermostatSetbackReport do
  @moduledoc """
   This module implements command THERMOSTAT_SETBACK_REPORT of the COMMAND_CLASS_THERMOSTAT_SETBACK command class.
   This command is used to report the setback state of the thermostat.

  Params:

    * `:type` - one of :no_override | :temporary_override | :permanent_override (required)

    * `:state` - one of a number between -12.8 and 12, or :frost_protection | :energy_saving(required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetback

  @type param :: {:type, ThermostatSetback.type()} | {:state, ThermostatSetback.state()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setback_report,
      command_byte: 0x03,
      command_class: ThermostatSetback,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type_byte = Command.param!(command, :type) |> ThermostatSetback.encode_type()
    state_byte = Command.param!(command, :state) |> ThermostatSetback.encode_state()
    <<0x00::size(6), type_byte::size(2), state_byte>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_::size(6), type_byte::size(2), state_byte>>) do
    with {:ok, type} <- ThermostatSetback.decode_type(type_byte),
         {:ok, state} <- ThermostatSetback.decode_state(state_byte) do
      {:ok, [type: type, state: state]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
