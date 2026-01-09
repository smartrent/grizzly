defmodule Grizzly.ZWave.Commands.NoOperation do
  @moduledoc """
  This commands does nothing other than test if the node is responding

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
  def decode_params(_), do: {:ok, []}
end
