defmodule Grizzly.ZWave.Commands.AssociationGet do
  @moduledoc """
  Get the current destinations for the association group

  This should be respond to with a `Grizzly.ZWave.Commands.AssociationReport`

  Params:

    * `:grouping_identifier` - the group to request a report about (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:grouping_identifier, byte()}

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
