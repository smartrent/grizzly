defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupReport do
  @moduledoc """
  This command is used to advertise the association group that represents the
  most recently detected button.

  Params:

    * `:group` - the association group that represents the most recently
      detected button
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:group, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    group = Command.param!(command, :group)
    <<group>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<group>>) do
    {:ok, [group: group]}
  end
end
