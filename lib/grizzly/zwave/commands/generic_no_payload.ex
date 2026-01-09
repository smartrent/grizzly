defmodule Grizzly.ZWave.Commands.GenericNoPayload do
  @moduledoc """
  A generic command module for Z-Wave commands that have no payload.
  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
