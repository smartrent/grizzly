defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """

  alias Grizzly.SeqNumber

  @spec get_node_ids() :: Grizzly.send_command_response()
  def get_node_ids() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_list_get, seq_number: seq_number)
  end

  @spec reset_controller() :: Grizzly.send_command_response()
  def reset_controller() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :default_set, [seq_number: seq_number], timeout: 10_000)
  end
end
