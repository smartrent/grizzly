defmodule Grizzly.ZWave.Commands.CentralSceneNotification do
  @moduledoc """
  This command is used to advertise a scene key event.

  Versions 1 and 2 are obsolete.

  Params:

    * `:seq_number` - The receiving device uses the sequence number to ignore duplicates. (required)

    * `:slow_refresh` - This flag is used to advertise if the node is sending Key Held Down notifications at a slow rate. (required)

    * `:key_attribute` - This field advertises one or more events detected by the key (required)

    * `:scene_number` - The scene for the key event (required)

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:seq_number, non_neg_integer()}
          | {:slow_refresh, boolean}
          | {:key_attribute, CentralScene.key_attribute()}
          | {:scene_number, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :central_scene_notification,
      command_byte: 0x03,
      command_class: CentralScene,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    slow_refresh_bit = Command.param!(command, :slow_refresh) |> bool_to_bit()

    key_attribute_byte =
      Command.param!(command, :key_attribute) |> CentralScene.key_attribute_to_byte()

    scene_number = Command.param!(command, :scene_number)

    <<seq_number, slow_refresh_bit::1, 0x00::4, key_attribute_byte::3, scene_number>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<seq_number, slow_refresh_bit::1, 0x00::4, key_attribute_byte::3, scene_number>>
      ) do
    {:ok,
     [
       seq_number: seq_number,
       slow_refresh: slow_refresh_bit == 1,
       key_attribute: CentralScene.key_attribute_from_byte(key_attribute_byte),
       scene_number: scene_number
     ]}
  end
end
