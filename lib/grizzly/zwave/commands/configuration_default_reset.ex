defmodule Grizzly.ZWave.Commands.ConfigurationDefaultReset do
  @moduledoc """
  This module implements the Configuration Default Reset command from the
  Configuration command class.

  This command is used to reset all configuration parameters to their default
  values.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
