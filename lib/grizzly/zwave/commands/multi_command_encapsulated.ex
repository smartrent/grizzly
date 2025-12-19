defmodule Grizzly.ZWave.Commands.MultiCommandEncapsulated do
  @moduledoc """
  The Multi Command Encapsulated Command used to contain multiple Commands.

  Params:

    * `:commands` - the commands encapsulated in this one

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiCommand
  alias Grizzly.ZWave.Decoder

  @type param :: {:commands, [Command.t()]}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :multi_command_encapsulated,
      command_byte: 0x01,
      command_class: MultiCommand,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    commands = Command.param!(command, :commands)
    count = Enum.count(commands)
    encoded_commands = for command <- commands, into: <<>>, do: encode_command(command)
    <<count>> <> encoded_commands
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_number_of_commands, commands_binary::binary>>) do
    commands = decode_commands(commands_binary) |> Enum.reverse()
    {:ok, [commands: commands]}
  end

  defp encode_command(command) do
    command_class_byte = command.command_class.byte()
    command_byte = command.command_byte
    encoded_params = command.impl.encode_params(command)
    encoded_command = <<command_class_byte, command_byte>> <> encoded_params
    <<byte_size(encoded_command)>> <> encoded_command
  end

  defp decode_commands(<<>>), do: []

  defp decode_commands(<<length, command_binary::binary-size(length), others::binary>>) do
    command = decode_command(command_binary)
    [command | decode_commands(others)]
  end

  defp decode_command(
         <<_command_class_byte, _command_byte, _encoded_params::binary>> = command_binary
       ) do
    {:ok, command} = Decoder.from_binary(command_binary)
    command
  end
end
