defmodule Grizzly.ZWave.Commands.AssociationGroupInfoGet do
  @moduledoc """
  This command is used to request the properties of one or more association
  group.

  Params:

    * `:refresh_cache` - Whether to refresh cached info
    * `:all` - Get info on all association groups
    * `:group_id` - get info on this association group (required if `all` is
      false)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:all, boolean} | {:refresh_cache, boolean} | {:group_id, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    all? = Command.param!(command, :all)
    all_bit = if all?, do: 0x01, else: 0x00
    refresh_cache? = Command.param!(command, :refresh_cache)
    refresh_cache_bit = if refresh_cache?, do: 0x01, else: 0x00
    group_id = Command.param(command, :group_id, 0)
    <<refresh_cache_bit::1, all_bit::1, 0x00::6, group_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<refresh_cache_bit::1, all_bit::1, 0x00::6, group_id>>) do
    {:ok, [refresh_cache: refresh_cache_bit == 0x01, all: all_bit == 0x01, group_id: group_id]}
  end
end
