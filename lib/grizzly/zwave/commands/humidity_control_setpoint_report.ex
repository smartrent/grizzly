defmodule Grizzly.ZWave.Commands.HumidityControlSetpointReport do
  @moduledoc """
  HumidityControlSetpointReport

  ## Parameters

  * `:setpoint_type` - see `t:HumidityControlSetpoint.type/0`
  * `:scale` - see `t:HumidityControlSetpoint.scale/0`
  * `:value` - setpoint value
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  alias Grizzly.ZWave.Commands.HumidityControlSetpointSet

  @type param :: HumidityControlSetpointSet.param()

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_setpoint_report,
      command_byte: 0x03,
      command_class: HumidityControlSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  defdelegate encode_params(command), to: HumidityControlSetpointSet

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  defdelegate decode_params(binary), to: HumidityControlSetpointSet
end
