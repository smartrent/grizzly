defmodule Grizzly.ZWave.Commands.VersionCommandClassReport do
  @moduledoc """
  Reports the command class version for a device

  Params:

    * `:command_class` - the name of the command class the report is for
      (required)
    * `:version` - the version of the command class in the report (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Version

  @type param :: {:command_class, CommandClasses.command_class()} | {:version, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :version_command_class_report,
      command_byte: 0x14,
      command_class: Version,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    cc = Command.param!(command, :command_class)
    <<CommandClasses.to_byte(cc), Command.param!(command, :version)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<cc_byte, version>>) do
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
