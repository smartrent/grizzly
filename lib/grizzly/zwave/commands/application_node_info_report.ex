defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoReport do
  @moduledoc """
  Reports the Application Node Info with regards to the command classes that
  are supported

  Params:

    * `:command_classes` - list of command classes
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZIPGateway

  @type tagged_command_classes ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}

  @type param :: {:command_classes, [tagged_command_classes()]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :application_node_info_report,
      command_byte: 0x0D,
      command_class: ZIPGateway,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    command_classes = Command.param!(command, :command_classes)
    CommandClasses.command_class_list_to_binary(command_classes)
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(command_class_list_binary) do
    command_classes = CommandClasses.command_class_list_from_binary(command_class_list_binary)
    {:ok, [command_classes: command_classes]}
  end
end
