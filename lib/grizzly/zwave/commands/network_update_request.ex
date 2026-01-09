defmodule Grizzly.ZWave.Commands.NetworkUpdateRequest do
  @moduledoc """
  This command is used to request network topology updates from the SUC/SIS node.

  Params:

    * `:seq_number` - a sequence number for the commands (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:seq_number, Grizzly.seq_number()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    <<seq_number>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number>>) do
    {:ok, [seq_number: seq_number]}
  end
end
