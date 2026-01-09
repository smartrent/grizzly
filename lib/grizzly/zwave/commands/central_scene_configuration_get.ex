defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationGet do
  @moduledoc """
  This command is used to query the configuration of optional node capabilities
  for scene notifications

  Params: - none -
  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
