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

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type mode :: :remove_node_any | :remove_node_stop

  @impl Grizzly.ZWave.Command
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_remove,
      command_byte: 0x03,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    mode = Command.param(command, :mode, :remove_node_any)

    # the 0x00 is a reserved byte to be set to 0
    <<seq_number, 0x00, encode_mode(mode)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, _, mode_byte>>) do
    case decode_mode(mode_byte) do
      {:ok, mode} ->
        {:ok, [seq_number: seq_number, mode: mode]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  @spec encode_mode(mode()) :: 0x01 | 0x05
  def encode_mode(:remove_node_any), do: 0x01
  def encode_mode(:remove_node_stop), do: 0x05

  @spec decode_mode(byte()) :: {:ok, mode()} | {:error, DecodeError.t()}
  def decode_mode(0x01), do: {:ok, :remove_node_any}
  def decode_mode(0x05), do: {:ok, :remove_node_stop}

  def decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :node_remove}}
end
