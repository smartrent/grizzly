defmodule Grizzly.ZWave.Commands.CommandClassReport do
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

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :command_class_report,
      command_byte: 0x14,
      command_class: Version,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    cc = Command.param!(command, :command_class)
    <<CommandClasses.to_byte(cc), Command.param!(command, :version)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<cc_byte, version>>) do
    case CommandClasses.from_byte(cc_byte) do
      {:ok, cc} ->
        {:ok, [command_class: cc, version: version]}

      {:error, _} ->
        {:error,
         %DecodeError{value: cc_byte, param: :command_class, command: :command_class_report}}
    end
  end
end
