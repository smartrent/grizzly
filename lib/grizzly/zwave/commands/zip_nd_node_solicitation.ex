defmodule Grizzly.ZWave.Commands.ZipNdNodeSolicitation do
  @moduledoc """
  The Z/IP Node Solicitation command is used to resolve an IPv6 address of a
  Z-Wave node to the NodeID (link-layer address) of that node in its actual
  Z-Wave HAN / IP subnet.

  Several IPv6 addresses MAY be resolved to the same NodeID.

  ### Params

  * `ipv6_address`: the IPv6 address to be resolved. Required.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipNd

  @type param :: {:ipv6_address, :inet.ip6_address()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_nd_node_solicitation,
      command_byte: 0x03,
      command_class: ZipNd,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    ipv6_address = Command.param!(command, :ipv6_address)

    <<0::8, 0::8>> <> ZipNd.encode_ipv6_address(ipv6_address)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved::8, _unused::8, addr::binary-size(16)>>) do
    {:ok, [ipv6_address: ZipNd.decode_ipv6_address(addr)]}
  end
end
