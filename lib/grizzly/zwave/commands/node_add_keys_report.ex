defmodule Grizzly.ZWave.Commands.NodeAddKeysReport do
  @moduledoc """
  Command to report the security keys requested by an including node if that
  node is participating in S2 bootstrapping.

  Params:

    * `:seq_number` - the sequence number of the command (required)
    * `:csa` - if the including node is doing client side authentication
      (require)
    * `:requested_keys` - a list of requested security keys see
      `Grizzly.ZWave.Security` for more information. (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.Security

  @impl Grizzly.ZWave.Command
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add_keys_report,
      command_byte: 0x11,
      command_class: NetworkManagementInclusion,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    csa = Command.param!(command, :csa)
    requested_keys = Command.param!(command, :requested_keys)

    <<seq_number, encode_csa(csa), encode_requested_keys(requested_keys)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, csa, requested_keys>>) do
    {:ok,
     [
       seq_number: seq_number,
       csa: decode_csa(csa),
       requested_keys: decode_requested_keys(requested_keys)
     ]}
  end

  def encode_csa(true), do: 0x01
  def encode_csa(false), do: 0x00

  def decode_csa(0x01), do: true
  def decode_csa(0x00), do: false

  def decode_requested_keys(requested_keys_mask), do: Security.byte_to_keys(requested_keys_mask)

  def encode_requested_keys(requested_keys), do: Security.keys_to_byte(requested_keys)
end
