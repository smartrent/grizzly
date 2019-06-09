defmodule Grizzly.CommandClass.CommandClassVersion do
  @moduledoc """
    Module for generating the correct command for getting command versions
  """

  alias Grizzly.CommandClass.Mappings
  require Logger

  @doc """
  Decode version report data
  """
  @spec decode_report_data(<<_::16>>) :: %{command_class: atom, version: byte}
  def decode_report_data(<<command_class_byte, version>>) do
    command_class =
      case Mappings.from_byte(command_class_byte) do
        {:unk, _} -> :invalid
        command_class -> command_class
      end

    %{
      command_class: command_class,
      version: version
    }
  end

  @doc """
  Encode command class
  """
  @spec encode_command_class(atom) :: byte
  def encode_command_class(command_class) do
    case Mappings.to_byte(command_class) do
      {:unk, _} ->
        _ = Logger.warn("Unknown command class #{inspect(command_class)}")
        0x00

      byte ->
        byte
    end
  end
end
