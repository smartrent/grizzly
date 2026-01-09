defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupGet do
  @moduledoc """
  This command allows a portable controller to interactively create associations
  from a multi-button device to a destination that is out of direct range.

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
