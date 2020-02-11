defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """

  alias Grizzly.SeqNumber
  alias Grizzly.ZWave.Command

  @spec get_node_ids() :: {:ok, Command.t()}
  def get_node_ids() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_list_get, seq_number: seq_number)
  end
end
