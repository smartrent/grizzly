defmodule Grizzly.ZWave.Commands.VersionCommandClassGet do
  @moduledoc """
  This module implements command VERSION_COMMAND_CLASS_GET of command class COMMAND_CLASS_VERSION

  Params:

   * `:command_class` - the atom name of a command class (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.DecodeError

  @type param :: {:command_class, atom}

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

  @impl Grizzly.ZWave.Command
  def report_matches_get?(get, report) do
    Command.param!(get, :command_class) == Command.param!(report, :command_class)
  end
end
