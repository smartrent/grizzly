defmodule Grizzly.ZWave.Commands.BasicGet do
  @moduledoc """
  This module implements the BASIC_GET command form the COMMAND_CLASS_BASIC
  command class

  Params: - none
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
