defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationSet do
  @moduledoc """
  This command is used to configure the use of optional node capabilities for scene notifications.

  Params:

    * `:slow_refresh` - This boolean field indicates whether the scene launching node must use Slow Refresh.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene

  @type param :: {:slow_refresh, boolean}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :central_scene_configuration_set,
      command_byte: 0x04,
      command_class: CentralScene,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    slow_refresh_bit = Command.param!(command, :slow_refresh) |> CentralScene.boolean_to_bit()
    <<slow_refresh_bit::size(1), 0x00::size(7)>>
  end

  @impl true
  def decode_params(<<slow_refresh_bit::size(1), _reserved::size(7)>>) do
    {:ok, [slow_refresh: slow_refresh_bit == 1]}
  end
end
