defmodule Grizzly.ZWave.Commands.HumidityControlModeSetReport do
  @moduledoc """
  HumidityControlModeSet

  ## Parameters

  * `:mode`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlMode

  @type param :: {:mode, any()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    mode = Command.param!(command, :mode)
    <<0::4, HumidityControlMode.encode_mode(mode)::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, mode::4>>) do
    {:ok, [mode: HumidityControlMode.decode_mode(mode)]}
  end
end
