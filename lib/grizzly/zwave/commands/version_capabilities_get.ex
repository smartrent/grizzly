defmodule Grizzly.ZWave.Commands.VersionCapabilitiesGet do
  @moduledoc """
  This module implements command VERSION_CAPABILITIES_GET of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
