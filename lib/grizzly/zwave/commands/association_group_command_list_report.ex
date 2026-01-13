defmodule Grizzly.ZWave.Commands.AssociationGroupCommandListReport do
  @moduledoc """
  This command is used to advertise the commands that are sent via an actual
  association group.

  Params:

    * `:group_id` - the group identifier
    * `:commands` - lists of commands
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DecodeError

  require Logger

  @type param() :: {:group_id, byte()} | {:commands, [atom()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    group_id = Command.param!(command, :group_id)
    commands = Command.param!(command, :commands)
    encoded_commands = encode_commands(commands)
    length = byte_size(encoded_commands)
    <<group_id, length>> <> encoded_commands
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<group_id, length, commands_binary::binary>>) do
    case decode_commands(length, commands_binary) do
      {:ok, commands} ->
        {:ok, [group_id: group_id, commands: commands]}

      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp encode_commands(command_names) do
    specs = Enum.map(command_names, &Commands.spec_for!/1)

    for spec <- specs, into: <<>> do
      command_class_byte = CommandClasses.to_byte(spec.command_class)
      <<command_class_byte, spec.command_byte>>
    end
  end

  defp decode_commands(length, encoded_commands_list) do
    # Ignore extraneous bytes, e.g. trailing 0s
    byte_list = :erlang.binary_to_list(encoded_commands_list) |> Enum.take(length)

    if Enum.count(byte_list) != length do
      Logger.warning("[Grizzly] Invalid length #{length} for list of commands")

      {:error,
       %DecodeError{
         value: encoded_commands_list,
         param: :commands,
         command: :association_group_command_list_report
       }}
    else
      {_, group_command_list} =
        Enum.reduce(
          byte_list,
          {[], []},
          fn byte, {buffer, acc} ->
            updated_buffer = buffer ++ [byte]

            case specified_command(updated_buffer) do
              nil ->
                {updated_buffer, acc}

              command ->
                {[], [command | acc]}
            end
          end
        )

      answer = group_command_list |> Enum.reverse()
      {:ok, answer}
    end
  end

  defp specified_command([_]), do: nil
  defp specified_command([cc_byte, _]) when cc_byte in [0xF1..0xFF], do: nil

  defp specified_command([cc_byte1, cc_byte2, c_byte]) when cc_byte1 in [0xF1..0xFF] do
    _ =
      Logger.warning(
        "[Grizzly] Ignoring command #{c_byte} from extended command class #{cc_byte1}, #{cc_byte2}"
      )

    :unknown
  end

  defp specified_command([cc_byte, c_byte]) do
    case Commands.spec_for(cc_byte, c_byte) do
      {:error, :unknown_command} ->
        Logger.warning("[Grizzly] Unmapped command #{c_byte} of command class #{cc_byte}")
        :unknown

      {:ok, spec} ->
        spec.name
    end
  end

  defp specified_command(_), do: :unknown
end
