defmodule Grizzly.ZWave.Commands.UserCodeChecksumGet do
  @moduledoc """
  What does this command do??

  Params:

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
