defmodule Grizzly.ZWave.Commands.ZipNodeAdvertisement do
  @moduledoc """
  Sent by a Z/IP Gateway in response to a unicast Zip Node
  Solicitation or a unicast Zip Inverse Node Solicitation. The Zip Node Advertisement SHOULD advertise
  valid information in both the IPv6 Address and NodeID fields if such information.

  Params:

    * `:node_id - The node id (required)

    * `:local` - whether the requester asked for the site-local address (required)

    * `:validity` - indicates the validity of the returned information (required)

    * `:ipv6_address` - the IPv6 Address of the node (required)

    * `:home_id` - Unique network address of the link layer network. All nodes in a Z-Wave network share the same Home ID (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipND

  @type param ::
          {:node_id, byte}
          | {:local, boolean}
          | {:validity, ZipND.validity()}
          | {:ipv6_address, ZipND.ipv6()}
          | {:home_id, non_neg_integer}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_node_advertisement,
      command_byte: 0x01,
      command_class: ZipND,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    local_bit = if Command.param!(command, :local), do: 0x01, else: 0x00
    validity_byte = Command.param!(command, :validity) |> ZipND.validity_to_byte()
    ipv6_binary = Command.param!(command, :ipv6_address) |> ZipND.encode_ipv6_address()
    home_id = Command.param!(command, :home_id)

    <<0x00::size(5), local_bit::size(1), validity_byte::size(2), node_id>> <>
      ipv6_binary <> <<home_id::integer-unsigned-size(4)-unit(8)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<_reserved::size(5), local_bit::size(1), validity_byte::size(2), node_id,
          ipv6_binary::binary-size(16), home_id::integer-unsigned-size(4)-unit(8)>>
      ) do
    with {:ok, ipv6_address} <- ZipND.decode_ipv6_address(ipv6_binary),
         {:ok, validity} <- ZipND.validity_from_byte(validity_byte) do
      {:ok,
       [
         node_id: node_id,
         validity: validity,
         local: local_bit == 0x01,
         ipv6_address: ipv6_address,
         home_id: home_id
       ]}
    else
      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :zip_node_advertisement}}
    end
  end
end
