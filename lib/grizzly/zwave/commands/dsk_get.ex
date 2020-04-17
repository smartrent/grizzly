defmodule Grizzly.ZWave.Commands.DSKGet do
  @moduledoc """
  Request the S2 DSK of a Node

  The response to this command is DSKReport

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:add_mode` - some S2 nodes maybe have two different types of DSKs one
      being added into a Z-Wave network (learn mode) and another for adding
      other nodes in the network (add mode) (optional default `:learn_mode`)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @default_params [add_mode: :learn_mode]

  @type add_mode() :: :learn_mode | :add_mode

  @type param :: {:seq_number, ZWave.seq_number()} | {:add_mode, add_mode()}

  @impl true
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

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    add_mode = add_mode_to_byte(Command.param!(command, :add_mode))

    <<seq_number, add_mode>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number, _::size(7), add_mode_bit::size(1)>>) do
    {:ok, [seq_number: seq_number, add_mode: add_mode_from_bit(add_mode_bit)]}
  end

  @spec add_mode_to_byte(add_mode()) :: byte()
  def add_mode_to_byte(:learn_mode), do: 0x00
  def add_mode_to_byte(:add_mode), do: 0x01

  @spec add_mode_from_bit(0 | 1) :: add_mode()
  def add_mode_from_bit(0), do: :learn_mode
  def add_mode_from_bit(1), do: :add_mode
end
