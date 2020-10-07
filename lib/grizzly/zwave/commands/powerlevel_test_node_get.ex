defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeGet do
  @moduledoc """
  This command is used to request the result of the latest Powerlevel Test.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @impl true
  def new(params) do
    command = %Command{
      name: :powerlevel_test_node_get,
      command_byte: 0x05,
      command_class: Powerlevel,
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
