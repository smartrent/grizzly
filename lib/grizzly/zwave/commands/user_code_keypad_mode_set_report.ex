defmodule Grizzly.ZWave.Commands.UserCodeKeypadModeSetReport do
  @moduledoc """
  This command is used to set the keypad mode at the receiving node.

  Params:

  * `mode` - The keypad mode to set. See `t:Grizzly.ZWave.CommandClasses.UserCode.keypad_mode/0`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:mode, UserCode.keypad_mode()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mode = Command.param!(command, :mode)

    <<UserCode.keypad_mode_to_byte(mode)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<mode::8>>) do
    {:ok, [mode: UserCode.keypad_mode_from_byte(mode)]}
  end
end
