defmodule Grizzly.ZWave.Commands.HumidityControlOperatingStateReport do
  @moduledoc """
  HumidityControlOperatingStateReport

  ## Parameters

  * `:state`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlOperatingState

  @type param :: {:state, HumidityControlOperatingState.state()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    state = Command.param!(command, :state)
    <<0::4, HumidityControlOperatingState.encode_state(state)::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, state::4>>) do
    {:ok, [state: HumidityControlOperatingState.decode_state(state)]}
  end
end
