defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupGet do
  @moduledoc """
  This command allows a portable controller to interactively create associations from a multi-button
  device to a destination that is out of direct range.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @impl true
  def new(params) do
    command = %Command{
      name: :association_specific_group_get,
      command_byte: 0x0B,
      command_class: Association,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
