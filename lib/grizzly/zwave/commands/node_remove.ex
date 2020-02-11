defmodule Grizzly.ZWave.Commands.NodeRemove do
  @moduledoc """
  Z-Wave command NODE_REMOVE

  This command is useful for removing Z-Wave devices from the Z-Wave network

  This response to this command should be a
  `Grizzly.ZWave.Commands.NodeRemoveStatus`

  Params:

    * `:seq_number` - the sequence number for the network command (required)
    * `:mode` - the mode for the remove node process (optional default `:remove_node_any`)
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandHandlers.WaitReport

  @type mode :: :remove_node_any | :remove_node_stop

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_remove,
      command_class_name: :network_management_inclusion,
      command_byte: 0x03,
      command_class_byte: 0x34,
      params: params,
      handler: {WaitReport, complete_report: :node_remove_status},
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    mode = Command.param(command, :mode, :remove_node_any)

    # the 0x00 is a reserved byte to be set to 0
    <<seq_number, 0x00, encode_mode(mode)>>
  end

  @impl true
  def decode_params(<<seq_number, _, mode_byte>>) do
    [seq_number: seq_number, mode: decode_mode(mode_byte)]
  end

  @spec encode_mode(mode()) :: 0x01 | 0x05
  def encode_mode(:remove_node_any), do: 0x01
  def encode_mode(:remove_node_stop), do: 0x05

  @spec decode_mode(byte()) :: mode()
  def decode_mode(0x01), do: :remove_node_any
  def decode_mode(0x05), do: :remove_node_stop
end
