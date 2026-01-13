defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoReport do
  @moduledoc """
  Reports the Application Node Info with regards to the command classes that
  are supported

  Params:

    * `:command_classes` - list of command classes
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses

  @type tagged_command_classes ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}

  @type param :: {:command_classes, [tagged_command_classes()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command_classes = Command.param!(command, :command_classes)
    CommandClasses.command_class_list_to_binary(command_classes)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, command_class_list_binary) do
    command_classes = CommandClasses.command_class_list_from_binary(command_class_list_binary)
    {:ok, [command_classes: command_classes]}
  end
end
