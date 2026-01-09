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
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    <<Command.param!(command, :grouping_identifier)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<grouping_identifier>>),
    do: {:ok, [grouping_identifier: grouping_identifier]}
end
