defmodule Grizzly.ZWave.Commands.VersionZWaveSoftwareGet do
  @moduledoc """
  This module implements command VERSION_ZWAVE_SOFTWARE_GET of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Version

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :version_zwave_software_get,
      command_byte: 0x17,
      command_class: Version
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
