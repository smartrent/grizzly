defmodule Grizzly.ZWave.Commands.ZipNdInverseNodeSolicitation do
  @moduledoc """
  The Z/IP Inverse Node Solicitation command is used to resolve a NodeID of a
  Z-Wave node to an IPv6 address of that node in its actual Z-Wave HAN / IP subnet.

  Params:

  * `local`: true if the requester prefers the site-local address (ULA) even if
    a global adress exists. Default `true`.

  * `node_id`: the NodeID to be resolved to an IPv6 address. Required.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipNd

  @type param :: {:node_id, Grizzly.node_id()} | {:local, boolean()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_nd_inverse_node_solicitation,
      command_byte: 0x04,
      command_class: ZipNd,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    local = Command.param(command, :local, true) |> ZipNd.bool_to_bit()

    if node_id >= 0xFF do
      <<0::4, local::1, 0::3, 0xFF::8, node_id::16>>
    else
      <<0::4, local::1, 0::3, node_id::8>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved1::4, local::1, _reserved2::3, node_id::8, extended_node_id::16>>) do
    node_id =
      if node_id == 0xFF do
        extended_node_id
      else
        node_id
      end

    {:ok, [node_id: node_id, local: ZipNd.bit_to_bool(local)]}
  end

  def decode_params(<<_reserved1::4, local::1, _reserved2::3, node_id::8>>),
    do: {:ok, [node_id: node_id, local: ZipNd.bit_to_bool(local)]}
end
