defmodule Grizzly.ZWave.Commands.VersionCommandClassReport do
  @moduledoc """
  Reports the command class version for a device

  Params:

    * `:command_class` - the name of the command class the report is for
      (required)
    * `:version` - the version of the command class in the report (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.DecodeError

  @type param :: {:command_class, CommandClasses.command_class()} | {:version, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    cc = Command.param!(command, :command_class)
    <<CommandClasses.to_byte(cc), Command.param!(command, :version)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<cc_byte, version>>) do
    case CommandClasses.from_byte(cc_byte) do
      {:ok, cc} ->
        {:ok, [command_class: cc, version: version]}

      {:error, _} ->
        {:error,
         %DecodeError{
           value: cc_byte,
           param: :command_class,
           command: :version_command_class_report
         }}
    end
  end
end
