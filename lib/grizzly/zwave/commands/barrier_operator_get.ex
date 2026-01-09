defmodule Grizzly.ZWave.Commands.BarrierOperatorGet do
  @moduledoc """
  This command is used to request the current state of a barrier operator device.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
