defmodule Grizzly.ZWave.Commands.DoorLockOperationGet do
  @moduledoc """
  OperationGet request the door lock operating mode

  The response to this command should be
  `Grizzly.ZWave.Commands.OperationReport`

  Params: - none -
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, keyword()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
