defmodule Grizzly.ZWave.Commands.AssociationGroupNameReport do
  @moduledoc """
  This command is used to advertise the assigned name of an association group.

  Params:

    * `:group_id` - the group id
    * `:name` - the group's name

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo

  @type param() :: {:group_id, byte} | {:name, String.t()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_name_report,
      command_byte: 0x02,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    group_id = Command.param!(command, :group_id)
    name = Command.param!(command, :name)
    length = String.length(name)
    true = length in 0..42
    <<group_id, length>> <> name
  end

  @impl true
  # We've seen at least one device that sends an extraneous byte that needs to be ignored
  def decode_params(<<group_id, length, name::binary-size(length), _ignore::binary>>) do
    {:ok, [group_id: group_id, name: name]}
  end
end
