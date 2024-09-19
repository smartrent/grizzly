defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupReport do
  @moduledoc """
  This command is used to advertise the association group that represents the
  most recently detected button.

  Params:

    * `:group` - the association group that represents the most recently
      detected button
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @type param :: {:group, byte}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_specific_group_report,
      command_byte: 0x0C,
      command_class: Association,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    group = Command.param!(command, :group)
    <<group>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<group>>) do
    {:ok, [group: group]}
  end
end
