defmodule Grizzly.ZWave.Commands.DSKReport do
  @moduledoc """
  Report the DSK for the Z-Wave Node

  This command is the response to the `Grizzly.ZWave.Commands.DSKGet` command

  Params:

    * `:seq_number` - the sequence number for the networked command (required)
    * `:add_mode` - the add mode for the DSK see
      `Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode` for more
      information (required)
    * `:dsk` - the DSK string for the node, see `Grizzly.ZWave.DSK` for more
      information (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @type param ::
          {:seq_number, ZWave.seq_number()}
          | {:add_mode, NetworkManagementBasicNode.add_mode()}
          | {:dsk, DSK.t()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :dsk_report,
      command_byte: 0x09,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    add_mode = NetworkManagementBasicNode.add_mode_to_byte(Command.param!(command, :add_mode))
    dsk = Command.param!(command, :dsk)

    <<seq_number, add_mode>> <> dsk.raw
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, _::7, add_mode_bit::1, dsk_binary::binary>>) do
    add_mode = NetworkManagementBasicNode.add_mode_from_bit(add_mode_bit)
    {:ok, [seq_number: seq_number, add_mode: add_mode, dsk: DSK.new(dsk_binary)]}
  end
end
