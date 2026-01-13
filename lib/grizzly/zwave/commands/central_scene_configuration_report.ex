defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationReport do
  @moduledoc """
  This command is used to advertise the configuration of optional node
  capabilities for scene notifications.

  Params:

    * `:slow_refresh` - This boolean field indicates whether the scene launching
      node must use Slow Refresh.

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    slow_refresh_bit = Command.param!(command, :slow_refresh) |> bool_to_bit()
    <<slow_refresh_bit::1, 0x00::7>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<slow_refresh_bit::1, _reserved::7>>) do
    {:ok, [slow_refresh: slow_refresh_bit == 1]}
  end
end
