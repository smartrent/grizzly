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
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @type param :: {:seq_number, ZWave.seq_number()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :default_set,
      command_byte: 0x06,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    <<Command.param!(command, :seq_number)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number>>) do
    {:ok, [seq_number: seq_number]}
  end
end
