defmodule Grizzly.ZWave.Commands.MultiCommandEncapsulated do
  @moduledoc """
  The Multi Command Encapsulated Command used to contain multiple Commands.

  Params:

    * `:commands` - the commands encapsulated in this one

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiCommand

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

    encoded_commands =
      for command <- commands, into: <<>> do
        command_binary = Grizzly.ZWave.to_binary(command)
        <<byte_size(command_binary), command_binary::binary>>
      end

    <<count>> <> encoded_commands
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_number_of_commands, commands_binary::binary>>) do
    commands = decode_commands(commands_binary) |> Enum.reverse()
    {:ok, [commands: commands]}
  end

  defp decode_commands(<<>>), do: []

  defp decode_commands(<<length, command_binary::binary-size(length), others::binary>>) do
    command = decode_command(command_binary)
    [command | decode_commands(others)]
  end

  defp decode_command(
         <<_command_class_byte, _command_byte, _encoded_params::binary>> = command_binary
       ) do
    {:ok, command} = Grizzly.ZWave.from_binary(command_binary)
    command
  end
end
