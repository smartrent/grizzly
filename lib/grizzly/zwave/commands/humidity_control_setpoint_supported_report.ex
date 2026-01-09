defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSupportedReport do
  @moduledoc """
  HumidityControlSetpointSupportedReport

  ## Parameters

  * `:setpoint_types`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlSetpoint
  alias Grizzly.ZWave.DecodeError

  @type param :: {:setpoint_types, [HumidityControlSetpoint.type()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    command
    |> Command.param(:setpoint_types)
    |> Enum.map(&HumidityControlSetpoint.encode_type/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    setpoint_types =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControlSetpoint.decode_type/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [setpoint_types: setpoint_types]}
  end
end
