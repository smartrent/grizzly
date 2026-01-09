defmodule Grizzly.ZWave.Commands.AssociationGroupNameReport do
  @moduledoc """
  This command is used to advertise the assigned name of an association group.

  Params:

    * `:group_id` - the group id
    * `:name` - the group's name

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param() :: {:group_id, byte} | {:name, String.t()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    group_id = Command.param!(command, :group_id)
    name = Command.param!(command, :name)
    length = String.length(name)
    true = length in 0..42
    <<group_id, length>> <> name
  end

  @impl Grizzly.ZWave.Command
  # We've seen at least one device that sends an extraneous byte that needs to be ignored
  def decode_params(<<group_id, length, name::binary-size(length), _ignore::binary>>) do
    {:ok, [group_id: group_id, name: name]}
  end
end
