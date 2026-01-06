defmodule Grizzly.ZWave.Commands.FailedNodeReplace do
  @moduledoc """
  Command for FAILED_NODE_REPLACE

  Params:

    * `:seq_number` - the sequence number for the network command (required)
    * `:mode` - the inclusion mode (optional default `:node_add_any_s2`)
    * `:tx_opts` - the transmission options (optional default `:explore`)

  If your controller does not support the `NETWORK_MANAGEMENT_INCLUSION`
  version 2, you will ned to pass `:node_add_any` as the `:mode` parameter.

  This command should return the `NodeAddStatus` report after inclusion is
  complete.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion, as: NMI
  alias Grizzly.ZWave.DecodeError

  @type mode ::
          :start_failed_node_replace | :stop_failed_node_replace | :start_failed_node_replace_s2

  @type tx_opt :: :null | :low_power | :explore

  @type param :: {:mode, mode()} | {:tx_opt, tx_opt()} | {:seq_number, Grizzly.seq_number()}

  @impl Grizzly.ZWave.Command
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :failed_node_replace,
      command_byte: 0x09,
      command_class: NMI,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    mode = Command.param(command, :mode, :start_failed_node_replace_s2)
    tx_opt = Command.param(command, :tx_opt, :explore)

    <<seq_number, node_id, NMI.tx_opt_to_byte(tx_opt), encode_mode(mode)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, node_id, tx_opt_byte, mode_byte>>) do
    with {:ok, mode} <- decode_mode(mode_byte),
         {:ok, tx_opt} <- NMI.tx_opt_from_byte(tx_opt_byte) do
      {:ok, [mode: mode, seq_number: seq_number, node_id: node_id, tx_opt: tx_opt]}
    end
  end

  @spec encode_mode(mode()) :: byte()
  def encode_mode(:start_failed_node_replace), do: 0x01
  def encode_mode(:stop_failed_node_replace), do: 0x05
  def encode_mode(:start_failed_node_replace_s2), do: 0x07

  @spec decode_mode(byte()) :: {:ok, mode()} | {:error, DecodeError.t()}
  def decode_mode(0x01), do: {:ok, :start_failed_node_replace}
  def decode_mode(0x05), do: {:ok, :stop_failed_node_replace}
  def decode_mode(0x07), do: {:ok, :start_failed_node_replace_s2}

  def decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :failed_node_replace}}
end
