defmodule Grizzly.ZWave.Commands.NodeAdd do
  @moduledoc """
  Command for NODE_ADD

  Params:

    * `:seq_number` - the sequence number for the network command (required)
    * `:mode` - the inclusion mode (optional default `:node_add_any_s2`)
    * `:tx_opts` - the transmission options (optional default `:explore`)

  If your controller does not support the `NETWORK_MANAGEMENT_INCLUSION`
  version 2, you will ned to pass `:node_add_any` as the `:mode` parameter.

  This command should return the `NodeAddStatus` report after inclusion is complete
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type mode :: :node_add_any | :node_add_stop | :node_add_any_s2

  @type tx_opt :: :null | :low_power | :explore

  @type param :: {:mode, mode()} | {:tx_opt, tx_opt()} | {:seq_number, Grizzly.seq_number()}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add,
      command_byte: 0x01,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    mode = Command.param(command, :mode, :node_add_s2_any)
    tx_opt = Command.param(command, :tx_opt, :explore)

    <<seq_number, 0x00, encode_mode(mode), encode_tx_opt(tx_opt)>>
  end

  @impl true
  def decode_params(<<seq_number, _reserved, mode_byte, tx_opt_byte>>) do
    with {:ok, mode} <- decode_mode(mode_byte),
         {:ok, tx_opt} <- decode_tx_opt(tx_opt_byte) do
      {:ok, [mode: mode, seq_number: seq_number, tx_opt: tx_opt]}
    end
  end

  @spec encode_mode(mode()) :: byte()
  def encode_mode(:node_add_any), do: 0x01
  def encode_mode(:node_add_stop), do: 0x05
  def encode_mode(:node_add_s2_any), do: 0x07

  @spec encode_tx_opt(tx_opt()) :: byte()
  def encode_tx_opt(:null), do: 0x00
  def encode_tx_opt(:low_power), do: 0x02
  def encode_tx_opt(:explore), do: 0x20

  @spec decode_mode(byte()) :: {:ok, mode()} | {:error, DecodeError.t()}
  def decode_mode(0x01), do: {:ok, :node_add_any}
  def decode_mode(0x05), do: {:ok, :node_add_stop}
  def decode_mode(0x07), do: {:ok, :node_add_s2_any}
  def decode_mode(byte), do: {:error, %DecodeError{value: byte, param: :mode, command: :node_add}}

  @spec decode_tx_opt(byte()) :: {:ok, tx_opt()} | {:error, DecodeError.t()}
  def decode_tx_opt(0x00), do: {:ok, :null}
  def decode_tx_opt(0x02), do: {:ok, :low_power}
  def decode_tx_opt(0x20), do: {:ok, :explore}

  def decode_tx_opt(byte),
    do: {:error, %DecodeError{value: byte, param: :tx_opt, command: :node_add}}
end
