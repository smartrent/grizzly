defmodule Grizzly.ZWave.Commands.DSKGet do
  @moduledoc """
  Request the S2 DSK of a Node

  The response to this command is DSKReport

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:add_mode` - some S2 nodes maybe have two different types of DSKs one
      being added into a Z-Wave network (learn mode) and another for adding
      other nodes in the network (add mode) (optional default `:learn`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @default_params [add_mode: :learn]

  @type param ::
          {:seq_number, ZWave.seq_number()} | {:add_mode, NetworkManagementBasicNode.add_mode()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :dsk_get,
      command_byte: 0x08,
      command_class: NetworkManagementBasicNode,
      params: Keyword.merge(@default_params, params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    add_mode = NetworkManagementBasicNode.add_mode_to_byte(Command.param!(command, :add_mode))

    <<seq_number, add_mode>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number, _::7, add_mode_bit::1>>) do
    {:ok,
     [
       seq_number: seq_number,
       add_mode: NetworkManagementBasicNode.add_mode_from_bit(add_mode_bit)
     ]}
  end
end
