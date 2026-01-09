defmodule Grizzly.ZWave.Commands.UserCodeKeypadModeReport do
  @moduledoc """
  This command is used to report the keypad mode at the receiving node.

  Params:

  * `mode` - The keypad mode. See `t:Grizzly.ZWave.CommandClasses.UserCode.keypad_mode/0`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode
  alias Grizzly.ZWave.Commands

  @type param :: {:mode, UserCode.keypad_mode()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  defdelegate encode_params(command), to: Commands.UserCodeKeypadModeSet

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  defdelegate decode_params(command), to: Commands.UserCodeKeypadModeSet
end
