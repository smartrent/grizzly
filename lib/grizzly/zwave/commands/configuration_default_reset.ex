defmodule Grizzly.ZWave.Commands.ConfigurationDefaultReset do
  @moduledoc """
  This module implements the Configuration Default Reset command from the
  Configuration command class.

  This command is used to reset all configuration parameters to their default
  values.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Configuration

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :configuration_default_reset,
      command_byte: 0x01,
      command_class: Configuration,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
