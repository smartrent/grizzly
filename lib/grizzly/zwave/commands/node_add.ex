defmodule Grizzly.ZWave.Commands.NodeAdd do
  @moduledoc """
  Command for NODE_ADD

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

  @type mode :: :node_add_any | :node_add_stop | :node_add_any_s2

  @type tx_opt :: :null | :low_power | :explore

  @type param :: {:mode, mode()} | {:tx_opt, tx_opt()} | {:seq_number, Grizzly.seq_number()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    mode = Command.param(command, :mode, :node_add_s2_any)
    tx_opt = Command.param(command, :tx_opt, :explore)

    <<seq_number, 0x00, encode_mode(mode), NMI.tx_opt_to_byte(tx_opt)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, _reserved, mode_byte, tx_opt_byte>>) do
    with {:ok, mode} <- decode_mode(mode_byte),
         {:ok, tx_opt} <- NMI.tx_opt_from_byte(tx_opt_byte) do
      {:ok, [mode: mode, seq_number: seq_number, tx_opt: tx_opt]}
    end
  end

  @spec encode_mode(mode()) :: byte()
  def encode_mode(:node_add_any), do: 0x01
  def encode_mode(:node_add_stop), do: 0x05
  def encode_mode(:node_add_s2_any), do: 0x07

  @spec decode_mode(byte()) :: {:ok, mode()} | {:error, DecodeError.t()}
  def decode_mode(0x01), do: {:ok, :node_add_any}
  def decode_mode(0x05), do: {:ok, :node_add_stop}
  def decode_mode(0x07), do: {:ok, :node_add_s2_any}
  def decode_mode(byte), do: {:error, %DecodeError{value: byte, param: :mode, command: :node_add}}
end
