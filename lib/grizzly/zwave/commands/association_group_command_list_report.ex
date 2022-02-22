defmodule Grizzly.ZWave.Commands.AssociationGroupCommandListReport do
  @moduledoc """
  This command is used to advertise the commands that are sent via an actual
  association group.

  Params:

    * `:group_id` - the group identifier
    * `:commands` - lists of commands
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Decoder}
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo
  alias Grizzly.Commands.Table

  require Logger

  @type param() :: {:group_id, byte()} | {:commands, [atom()]}

  @impl true
  def new(params) do
    command = %Command{
      name: :association_group_command_list_report,
      command_byte: 0x06,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    group_id = Command.param!(command, :group_id)
    commands = Command.param!(command, :commands)
    encoded_commands = encode_commands(commands)
    length = byte_size(encoded_commands)
    <<group_id, length>> <> encoded_commands
  end

  @impl true
  def decode_params(<<group_id, length, commands_binary::binary>>) do
    case decode_commands(length, commands_binary) do
      {:ok, commands} ->
        {:ok, [group_id: group_id, commands: commands]}

      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp encode_commands(command_names) do
    commands =
      for command_name <- command_names do
        {:ok, command} = make_command(command_name)
        command
      end

    for command <- commands, into: <<>> do
      command_class_module = command.command_class
      command_class_byte = apply(command_class_module, :byte, [])
      <<command_class_byte, command.command_byte>>
    end
  end

  defp make_command(command_name) do
    {command_module, _} = Table.lookup(command_name)

    apply(command_module, :new, [[]])
  end

  defp decode_commands(length, encoded_commands_list) do
    # Ignore extraneous bytes, e.g. trailing 0s
    byte_list = :erlang.binary_to_list(encoded_commands_list) |> Enum.take(length)

    if Enum.count(byte_list) != length do
      Logger.warn("[Grizzly] Invalid length #{length} for list of commands")

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
      Logger.warn(
        "[Grizzly] Ignoring command #{c_byte} from extended command class #{cc_byte1}, #{cc_byte2}"
      )

    :unknown
  end

  defp specified_command([cc_byte, c_byte]) do
    case Decoder.command_module(cc_byte, c_byte) do
      {:error, :unsupported_command} ->
        Logger.warn("[Grizzly] Unmapped class #{c_byte} of command class #{cc_byte}")
        :unknown

      {:ok, command_module} ->
        {:ok, command} = apply(command_module, :new, [[]])
        command.name
    end
  end

  defp specified_command(_), do: :unknown
end
