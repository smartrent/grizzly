defmodule Grizzly.ZWave.Commands.AssociationGroupCommandListGet do
  @moduledoc """
  This command is used to request the commands that are sent via a given association group.

  Params:

    * `:allow_cache` - This field indicates that a Z-Wave Gateway device is allowed to intercept the request and return a
                       cached response on behalf of the specified target. (required)
    * `:group_id` - The group identifier (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo

  @type param() :: {:allow_cache, boolean()} | {:group_id, byte()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_command_list_get,
      command_byte: 0x05,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    allow_cache? = Command.param!(command, :allow_cache)
    group_id = Command.param!(command, :group_id)
    allow_cache_bit = if allow_cache?, do: 0x01, else: 0x00
    <<allow_cache_bit::size(1), 0x00::size(7), group_id>>
  end

  @impl true
  def decode_params(<<allow_cache_bit::size(1), 0x00::size(7), group_id>>) do
    {:ok, [allow_cache: allow_cache_bit == 0x01, group_id: group_id]}
  end
end
