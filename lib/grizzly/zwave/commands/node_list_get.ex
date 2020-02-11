defmodule Grizzly.ZWave.Commands.NodeListGet do
  @moduledoc """
  Module for the NODE_LIST_GET command

  Params:

    * `:seq_number` - the sequence number for the command (required)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandHandlers.WaitReport

  @type param :: {:seq_number, non_neg_integer()}

  @impl true
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :node_list_get,
      command_class_name: :network_management_proxy,
      command_class_byte: 0x52,
      command_byte: 0x01,
      handler: {WaitReport, complete_report: :node_list_report},
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    <<Command.param!(command, :seq_number)>>
  end

  @impl true
  def decode_params(<<seq_number>>), do: [seq_number: seq_number]
end
