defmodule Grizzly.ZWave.Commands.AssociationGroupingsReport do
  @moduledoc """
  This command is used to advertise the maximum number of association groups
  implemented by this node.

  Params:

    * `:supported_groupings` - the maximum number of association groups

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @type param :: {:supported_groupings, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_groupings_report,
      command_byte: 0x06,
      command_class: Association,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    supported_groupings = Command.param!(command, :supported_groupings)
    <<supported_groupings>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<supported_groupings>>) do
    {:ok, [supported_groupings: supported_groupings]}
  end
end
