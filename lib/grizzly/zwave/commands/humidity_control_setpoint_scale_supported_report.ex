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

  @type param :: {:scales, [HumidityControlSetpoint.scale()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command
    |> Command.param!(:scales)
    |> Enum.map(&HumidityControlSetpoint.encode_scale/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    scales =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControlSetpoint.decode_scale/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [scales: scales]}
  end
end
