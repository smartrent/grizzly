defmodule Grizzly.ZWave.Commands.UserCodeKeypadModeReport do
  @moduledoc """
  This command is used to report the keypad mode at the receiving node.

  Params:

  * `mode` - The keypad mode. See `t:Grizzly.ZWave.CommandClasses.UserCode.keypad_mode/0`
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, Commands}
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:mode, UserCode.keypad_mode()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_keypad_mode_report,
      command_byte: 0x0A,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  defdelegate encode_params(command), to: Commands.UserCodeKeypadModeSet

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  defdelegate decode_params(command), to: Commands.UserCodeKeypadModeSet
end
