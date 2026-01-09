defmodule Grizzly.ZWave.Commands.NodeProvisioningListIterationGet do
  @moduledoc """
  Module for working with the `NODE_PROVISIONING_LIST_ITERATION_GET` command

  This command is used to read the entire the provisioning list.

  Params:

    - `:seq_number` - the network command sequence number (required)
    - `:remaining_counter` - indicates the remaining amount of entries in the
      Provisioning List, not provided if starting (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type param ::
          {:seq_number, ZWave.seq_number()} | {:remaining_counter, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    remaining_counter = Command.param(command, :remaining_counter, 0xFF)
    seq_number = Command.param!(command, :seq_number)
    <<seq_number, remaining_counter>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, remaining_counter>>) do
    if remaining_counter == 0xFF do
      {:ok, [seq_number: seq_number]}
    else
      {:ok, [seq_number: seq_number, remaining_counter: remaining_counter]}
    end
  end
end
