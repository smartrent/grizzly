defmodule Grizzly.ZWave.Commands.HumidityControlModeSetReport do
  @moduledoc """
  HumidityControlModeSet

  ## Parameters

  * `:mode`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlMode
  alias Grizzly.ZWave.DecodeError

  @type param :: {:mode, any()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mode = Command.param!(command, :mode)
    <<0::4, HumidityControlMode.encode_mode(mode)::4>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_::4, mode::4>>) do
    {:ok, [mode: HumidityControlMode.decode_mode(mode)]}
  end
end
