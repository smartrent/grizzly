defmodule Grizzly.ZWave.Commands.VersionCommandClassGet do
  @moduledoc """
  This module implements command VERSION_COMMAND_CLASS_GET of command class COMMAND_CLASS_VERSION

  Params:

   * `:command_class` - the atom name of a command class (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Version

  @type param :: {:command_class, atom}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :version_command_class_get,
      command_byte: 0x13,
      command_class: Version,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    cc = Command.param!(command, :command_class)
    <<CommandClasses.to_byte(cc)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<cc_byte>>) do
    case CommandClasses.from_byte(cc_byte) do
      {:ok, cc} ->
        {:ok, command_class: cc}

      {:error, _} ->
        {:error,
         %DecodeError{value: cc_byte, param: :command_class, command: :version_command_class_get}}
    end
  end
end
