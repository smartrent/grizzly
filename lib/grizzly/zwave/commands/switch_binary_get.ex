defmodule Grizzly.ZWave.Commands.SwitchBinaryGet do
  @moduledoc """
  Get the command value of a binary switch

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  # TODO: make default implementation via using
  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  # TODO: make default implementation via using
  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
