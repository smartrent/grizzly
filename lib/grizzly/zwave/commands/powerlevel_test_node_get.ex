defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeGet do
  @moduledoc """
  This command is used to request the result of the latest Powerlevel Test.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
