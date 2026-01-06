defmodule Grizzly.ZWave.Commands.VersionGet do
  @moduledoc """
  This module implements command VERSION_GET of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Version

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :version_get,
      command_byte: 0x11,
      command_class: Version
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
