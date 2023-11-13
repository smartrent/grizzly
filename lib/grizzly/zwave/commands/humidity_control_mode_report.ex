defmodule Grizzly.ZWave.Commands.HumidityControlModeReport do
  @moduledoc """
  HumidityControlModeReport

  ## Parameters

  * `:mode`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.HumidityControlMode

  @type param :: {:mode, HumidityControlMode.mode()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_mode_report,
      command_byte: 0x03,
      command_class: HumidityControlMode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

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
