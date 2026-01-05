defmodule Grizzly.ZWave.Commands.HumidityControlOperatingStateGet do
  @moduledoc """
  HumidityControlOperatingStateGet
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlOperatingState
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_operating_state_get,
      command_byte: 0x01,
      command_class: HumidityControlOperatingState,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [keyword()]} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
