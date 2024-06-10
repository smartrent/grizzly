defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationReport do
  @moduledoc """
  This command is used to advertise the configuration of optional node
  capabilities for scene notifications.

  Params:

    * `:slow_refresh` - This boolean field indicates whether the scene launching
      node must use Slow Refresh.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene
  import Grizzly.ZWave.Encoding

  @impl true
  def new(params) do
    command = %Command{
      name: :central_scene_configuration_report,
      command_byte: 0x06,
      command_class: CentralScene,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    slow_refresh_bit = Command.param!(command, :slow_refresh) |> bool_to_bit()
    <<slow_refresh_bit::1, 0x00::7>>
  end

  @impl true
  def decode_params(<<slow_refresh_bit::1, _reserved::7>>) do
    {:ok, [slow_refresh: slow_refresh_bit == 1]}
  end
end
