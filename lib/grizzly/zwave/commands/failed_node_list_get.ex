defmodule Grizzly.ZWave.Commands.FailedNodeListGet do
  @moduledoc """
  This command is used to request the network node list that is marked as failing (or non-responsive).

  Params:

   * `:seq_number` - the sequence number of the networked command (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @type param ::
          {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :failed_node_list_get,
      command_byte: 0x0B,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

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
