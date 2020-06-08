defmodule Grizzly.ZWave.Commands.AssociationGroupInfoGet do
  @moduledoc """
  This command is used to request the properties of one or more association group.

  Params:

    * `:refresh_cache` - Whether to refresh cached info

    * `:all` - Get info on all assocation groups

    * `:group_id` - get info on this association group (required if `all` is false)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo

  @type param :: {:all, boolean} | {:refresh_cache, boolean} | {:group_id, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_info_get,
      command_byte: 0x03,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    all? = Command.param!(command, :all)
    all_bit = if all?, do: 0x01, else: 0x00
    refresh_cache? = Command.param!(command, :refresh_cache)
    refresh_cache_bit = if refresh_cache?, do: 0x01, else: 0x00
    group_id = Command.param(command, :group_id, 0)
    <<refresh_cache_bit::size(1), all_bit::size(1), 0x00::size(6), group_id>>
  end

  @impl true
  def decode_params(<<refresh_cache_bit::size(1), all_bit::size(1), 0x00::size(6), group_id>>) do
    {:ok, [refresh_cache: refresh_cache_bit == 0x01, all: all_bit == 0x01, group_id: group_id]}
  end
end
