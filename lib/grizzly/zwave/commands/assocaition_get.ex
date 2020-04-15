defmodule Grizzly.ZWave.Commands.AssociationGet do
  @moduledoc """
  Get the current destinations for the association group

  This should be respond to with a `Grizzly.ZWave.Commands.AssociationReport`

  Params:

    * `:grouping_identifier` - the group to request a report about (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @type param :: {:grouping_identifier, byte()}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_get,
      command_byte: 0x02,
      command_class: Association,
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
  @spec decode_params(binary()) :: [param()]
  def decode_params(<<grouping_identifier>>), do: [grouping_identifier: grouping_identifier]
end
