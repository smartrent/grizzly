defmodule Grizzly.ZWave.Commands.HumidityControlOperatingStateReport do
  @moduledoc """
  HumidityControlOperatingStateReport

  ## Parameters

  * `:state`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlOperatingState
  alias Grizzly.ZWave.DecodeError

  @type param :: {:state, HumidityControlOperatingState.state()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :humidity_control_operating_state_report,
      command_byte: 0x02,
      command_class: HumidityControlOperatingState,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    state = Command.param!(command, :state)
    <<0::4, HumidityControlOperatingState.encode_state(state)::4>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_::4, state::4>>) do
    {:ok, [state: HumidityControlOperatingState.decode_state(state)]}
  end
end
