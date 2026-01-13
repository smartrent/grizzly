defmodule Grizzly.ZWave.Commands.AssociationGroupNameGet do
  @moduledoc """
  This command is used to query the name of an association group.

  Params:

    * `:group_id` - the group identifier

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param() :: {:group_id, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    group_id = Command.param!(command, :group_id)
    <<group_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<group_id>>) do
    {:ok, [group_id: group_id]}
  end
end
