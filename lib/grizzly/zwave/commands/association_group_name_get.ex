defmodule Grizzly.ZWave.Commands.AssociationGroupNameGet do
  @moduledoc """
  This command is used to query the name of an association group.

  Params:

    * `:group_id` - the group identifier

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo

  @type param() :: {:group_id, byte}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_name_get,
      command_byte: 0x01,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    group_id = Command.param!(command, :group_id)
    <<group_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<group_id>>) do
    {:ok, [group_id: group_id]}
  end
end
