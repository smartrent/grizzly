defmodule Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedReport do
  @moduledoc """
  HumidityControlSetpointScaleSupportedReport

  ## Parameters

  * `:scales`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  alias Grizzly.ZWave.DecodeError

  @type param :: {:scales, [HumidityControlSetpoint.scale()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_setpoint_scale_supported_report,
      command_byte: 0x07,
      command_class: HumidityControlSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    command
    |> Command.param!(:scales)
    |> Enum.map(&HumidityControlSetpoint.encode_scale/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    scales =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControlSetpoint.decode_scale/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [scales: scales]}
  end
end
