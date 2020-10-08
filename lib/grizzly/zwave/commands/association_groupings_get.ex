defmodule Grizzly.ZWave.Commands.AssociationGroupingsGet do
  @moduledoc """
  This command is used to request the number of association groups that this node supports.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @impl true
  def new(params \\ []) do
    command = %Command{
      name: :association_groupings_get,
      command_byte: 0x05,
      command_class: Association,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
