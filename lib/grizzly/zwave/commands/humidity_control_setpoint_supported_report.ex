defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSupportedReport do
  @moduledoc """
  HumidityControlSetpointSupportedReport

  ## Parameters

  * `:setpoint_types`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControl

  @type param :: {:setpoint_types, [HumidityControl.setpoint_type()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command
    |> Command.param(:setpoint_types)
    |> Enum.map(&HumidityControl.encode_setpoint_type/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    setpoint_types =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControl.decode_setpoint_type/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [setpoint_types: setpoint_types]}
  end
end
