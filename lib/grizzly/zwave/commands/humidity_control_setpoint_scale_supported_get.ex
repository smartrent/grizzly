defmodule Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedGet do
  @moduledoc """
  HumidityControlSetpointScaleSupportedGet
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  alias Grizzly.ZWave.DecodeError

  @type param :: {:setpoint_type, HumidityControlSetpoint.type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_setpoint_scale_supported_get,
      command_byte: 0x06,
      command_class: HumidityControlSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    setpoint_type = Command.param!(command, :setpoint_type)
    <<0::4, HumidityControlSetpoint.encode_type(setpoint_type)::4>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_::4, setpoint_type::4>>) do
    {:ok, [setpoint_type: HumidityControlSetpoint.decode_type(setpoint_type)]}
  end
end
