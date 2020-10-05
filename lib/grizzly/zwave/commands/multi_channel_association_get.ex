defmodule Grizzly.ZWave.Commands.MultiChannelAssociationGet do
  @moduledoc """
  This command is used to request the current destinations of a given association group.

  Params:

    * `:grouping_identifier` - the actual association group

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannelAssociation

  @type param :: {:grouping_identifier, byte()}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_association_get,
      command_byte: 0x02,
      command_class: MultiChannelAssociation,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    <<Command.param!(command, :grouping_identifier)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<grouping_identifier>>),
    do: {:ok, [grouping_identifier: grouping_identifier]}
end
