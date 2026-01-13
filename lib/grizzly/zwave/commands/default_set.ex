defmodule Grizzly.ZWave.Commands.DefaultSet do
  @moduledoc """
  Reset a Node Z-Wave node back to factory default state

  The response to this command should be the
  `Grizzly.ZWave.Commands.DefaultSetComplete` command.

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type param :: {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    <<Command.param!(command, :seq_number)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number>>) do
    {:ok, [seq_number: seq_number]}
  end
end
