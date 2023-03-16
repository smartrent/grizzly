defmodule Grizzly.ZWave.Commands.ZipNdNodeAdvertisement do
  @moduledoc """
  The Z/IP Node Advertisement command is sent by a Z/IP Gateway in response to
  a Node Solicitation or Inverse Node Solicitation command.

  Params:

  * `local`: whether the requester asked for the site-local address (ULA).
  * `validity`: indicates the validity of the returned information.
    See `t:Grizzly.ZWave.CommandClasses.ZipNd.validity/0`.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipNd

  @type param ::
          {:node_id, Grizzly.node_id()}
          | {:ipv6_address, :inet.ip6_address()}
          | {:local, boolean()}
          | {:validity, ZipNd.validity()}
          | {:home_id, 0x00000000..0xFFFFFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_nd_node_advertisement,
      command_byte: 0x01,
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
    local = Command.param!(command, :local) |> ZipNd.bool_to_bit()
    validity = Command.param!(command, :validity) |> ZipNd.encode_validity()
    addr = Command.param!(command, :ipv6_address) |> ZipNd.encode_ipv6_address()
    home_id = Command.param!(command, :home_id)

    if node_id >= 0xFF do
      <<0::5, local::1, validity::2, 0xFF::8, addr::binary-size(16), home_id::32, node_id::16>>
    else
      <<0::5, local::1, validity::2, node_id::8, addr::binary-size(16), home_id::32>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # v2
  def decode_params(
        <<_reserved::5, local::1, validity::2, node_id::8, ipv6_addr::binary-size(16),
          home_id::32, extended_node_id::16>>
      ) do
    node_id =
      if node_id == 0xFF do
        extended_node_id
      else
        node_id
      end

    {:ok,
     [
       local: ZipNd.bit_to_bool(local),
       validity: ZipNd.decode_validity(validity),
       ipv6_address: ZipNd.decode_ipv6_address(ipv6_addr),
       home_id: home_id,
       node_id: node_id
     ]}
  end

  # v1
  def decode_params(
        <<_reserved::5, local::1, validity::2, node_id::8, ipv6_addr::binary-size(16),
          home_id::32>>
      ) do
    {:ok,
     [
       local: ZipNd.bit_to_bool(local),
       validity: ZipNd.decode_validity(validity),
       ipv6_address: ZipNd.decode_ipv6_address(ipv6_addr),
       home_id: home_id,
       node_id: node_id
     ]}
  end
end
