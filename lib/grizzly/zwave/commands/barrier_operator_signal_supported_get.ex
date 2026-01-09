defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedGet do
  @moduledoc """
  This command is used to query a device for available subsystems which may be controlled via Z-Wave.

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
