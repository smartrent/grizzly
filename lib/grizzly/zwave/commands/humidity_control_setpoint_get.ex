defmodule Grizzly.ZWave.Commands.HumidityControlSetpointGet do
  @moduledoc """
  HumidityControlSetpointGet

  ## Parameters

  * `:setpoint_type` - see `t:HumidityControlSetpoint.type/0`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint

  @type param :: {:setpoint_type, HumidityControlSetpoint.type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_setpoint_get,
      command_byte: 0x02,
      command_class: HumidityControlSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type = Command.param!(command, :setpoint_type)
    <<0::4, encode_type(type)::4>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_::4, type::4>>) do
    {:ok, [setpoint_type: decode_type(type)]}
  end
end
