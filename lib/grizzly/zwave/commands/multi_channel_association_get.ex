defmodule Grizzly.ZWave.Commands.MultiChannelAssociationGet do
  @moduledoc """
  This command is used to request the current destinations of a given association group.

  Params:

    * `:grouping_identifier` - the actual association group
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param() :: {:grouping_identifier, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    <<Command.param!(command, :grouping_identifier)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<grouping_identifier>>),
    do: {:ok, [grouping_identifier: grouping_identifier]}
end
