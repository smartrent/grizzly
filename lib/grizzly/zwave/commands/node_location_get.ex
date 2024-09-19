defmodule Grizzly.ZWave.Commands.NodeLocationGet do
  @moduledoc """
  This command is used to request the stored location from a node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NodeNaming

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :node_location_get,
      command_byte: 0x05,
      command_class: NodeNaming,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<>>) do
    {:ok, []}
  end
end
