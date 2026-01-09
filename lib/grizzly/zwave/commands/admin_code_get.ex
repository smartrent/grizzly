defmodule Grizzly.ZWave.Commands.AdminCodeGet do
  @moduledoc """
  AdminCodeGet gets a lock's admin code.

  Params:

    * `:code` - a 4 - 10 master code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Command
  @spec decode_params(binary()) :: {:ok, keyword()}
  def decode_params(_) do
    {:ok, []}
  end
end
