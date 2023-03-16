defmodule Grizzly.ZWave.CommandClasses.ZipNd do
  @moduledoc """
  Z/IP Neighbor Discovery
  """

  @behaviour Grizzly.ZWave.CommandClass

  @typedoc """
  Indicates the validity of the returned information.

  * `:information_ok`: both the IPv6 address and NodeID are valid
  * `:information_obsolete`: the information is obsolete, typically because the node
    is no longer present in the network
  * `:information_not_found`: the information could not be found
  """
  @type validity :: :information_ok | :information_obsolete | :information_not_found

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x58

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :zip_nd

  @spec bit_to_bool(0 | 1) :: boolean()
  def bit_to_bool(0), do: false
  def bit_to_bool(1), do: true

  @spec bool_to_bit(boolean()) :: 0 | 1
  def bool_to_bit(false), do: 0
  def bool_to_bit(true), do: 1

  @spec encode_ipv6_address(:inet.ip6_address()) :: <<_::128>>
  def encode_ipv6_address({a, b, c, d, e, f, g, h}) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>
  end

  @spec encode_ipv6_address(<<_::128>>) :: :inet.ip6_address()
  def decode_ipv6_address(
        <<addr1::16, addr2::16, addr3::16, addr4::16, addr5::16, addr6::16, addr7::16, addr8::16>>
      ),
      do: {addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8}

  @spec encode_validity(validity()) :: 0..2
  def encode_validity(:information_ok), do: 0x00
  def encode_validity(:information_obsolete), do: 0x01
  def encode_validity(:information_not_found), do: 0x02

  @spec decode_validity(0..2) :: validity()
  def decode_validity(0x00), do: :information_ok
  def decode_validity(0x01), do: :information_obsolete
  def decode_validity(0x02), do: :information_not_found
end
