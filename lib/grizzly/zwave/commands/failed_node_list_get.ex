defmodule Grizzly.ZWave.Commands.FailedNodeListGet do
  @moduledoc """
  This command is used to request the network node list that is marked as failing (or non-responsive).

  Params:

   * `:seq_number` - the sequence number of the networked command (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type param ::
          {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    <<seq_number>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number>>) do
    {:ok, [seq_number: seq_number]}
  end
end
