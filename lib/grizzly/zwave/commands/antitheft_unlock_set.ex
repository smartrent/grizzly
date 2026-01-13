defmodule Grizzly.ZWave.Commands.AntitheftUnlockSet do
  @moduledoc """
  This command is used to unlock a node that is currently locked.

  Params:

    * `:magic_code` - This field contains the Magic Code used to unlock the node.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AntitheftUnlock

  @type param :: {:magic_code, String.t()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    magic_code = Command.param!(command, :magic_code) |> AntitheftUnlock.validate_magic_code()
    <<0x00::4, byte_size(magic_code)::size(4)>> <> magic_code
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<0x00::4, magic_code_size::4, magic_code::binary-size(magic_code_size)>>
      ) do
    {:ok, [magic_code: magic_code]}
  end
end
