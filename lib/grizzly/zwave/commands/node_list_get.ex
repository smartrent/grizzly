defmodule Grizzly.ZWave.Commands.NodeListGet do
  @moduledoc """
  Module for the NODE_LIST_GET command

  Params:

    * `:seq_number` - the sequence number for the command (required)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @type param :: {:seq_number, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :node_list_get,
      command_byte: 0x01,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    <<Command.param!(command, :seq_number)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number>>), do: {:ok, [seq_number: seq_number]}
end
