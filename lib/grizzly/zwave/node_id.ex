defmodule Grizzly.ZWave.NodeId do
  @moduledoc false

  # helper mode for encoding and parsing node ids

  alias Grizzly.ZWave

  # When encoding for 16 bit node ids in the context of the node remove family of
  # command (node ids > 255) the 8 bit node id byte of the binary needs to be set
  # to 0xFF as per the specification.

  # In ZWA_Z-Wave Network Protocol Command Class Specification 12.0.0.pdf:

  # For example in sections 4.5.13.2 and 4.4.13.3:
  #   "This field MUST be set to 0xFF if the removed NodeID is greater than 255."

  # This only is used for version 4 parsing and encoding.
  @node_id_is_16_bit 0xFF

  @doc """
  Encode the node id
  """
  @spec encode(ZWave.node_id()) :: binary()
  def encode(node_id), do: <<node_id>>

  @typedoc """
  Options for extended format encoding

  * `:delimiter` - when the 8 bit node id and 16 bit node id bytes do not follow
    in sequence next to each other, this option allows the information between
    the two formats to be passed.
  """
  @type extended_encoding_opt() :: {:delimiter, binary()}

  @doc """
  Encode the node id using the extended node id format

  The format for command classes that support extended node ids is:

  ```
  <<0xFF, 16_bit_node_id>>
  ```

  Or

  ```
  <<8_bit_node_id, 16_bits_that_match_8_bit_node_id>>
  ```

  When using the extended format encoding as passing an 8 bit node id the
  specification often times states that the remaining 2 bytes at the end of the
  binary must match the node id passed to the 8 bit node id byte. For example:

  ```elixir
  iex> encode_extended(0x05)
  <<0x05, 0x00, 0x05>>
  ```

  Since the node id fits within the 8 bit node id field that is the first byte.
  The next two bytes (16 bits) is that node id repeated within the 2 byte space
  required to fill the total number of bytes for the extended format encoding.

  When the 8 bit node id and the 16 bit node id bytes are not in sequence and
  there other information between them you can pass the `:delimiter` option to
  ensure that binary is in between the 8 bit node and the 16 bit node id bytes.

  ```elixir
  iex> encode_extended(0x10, delimiter: <<0xA0, 0xB0>>)
  <<0x10, 0xA0, 0xB0, 0x00, 0x10>>
  iex> encode_extended(0x1010, delimiter: <<0xA0, 0xB0>>)
  <<0xFF, 0xA0, 0xB0, 0x10, 0x10>>
  ```
  """
  @spec encode_extended(ZWave.node_id(), [extended_encoding_opt()]) :: binary()
  def encode_extended(node_ids, opts \\ [])

  def encode_extended(node_id, opts) when node_id < 233 do
    case Keyword.get(opts, :delimiter) do
      nil ->
        <<node_id, node_id::16>>

      padding ->
        <<node_id, padding::binary, node_id::16>>
    end
  end

  def encode_extended(node_id, opts) when node_id > 255 and node_id <= 65535 do
    case Keyword.get(opts, :delimiter) do
      nil ->
        <<@node_id_is_16_bit, node_id::16>>

      padding ->
        <<@node_id_is_16_bit, padding::binary, node_id::16>>
    end
  end

  @typedoc """
  Parsing options

  * `:delimiter_size` - when the 8 bit node id and the 16 bit node are not in
    sequence and are separated by bytes in between them you can specify the byte
    size of the delimiter.
  """
  @type parse_opt() :: {:delimiter_size, non_neg_integer()}

  @doc """
  Parse the binary that contains the node id

  For node id binaries that support the extended node id format but contain
  bytes in between the 8 bit node id byte and the 16 bit node id bytes the
  options `:delimiter_size` can be passed to account for these in between
  bytes in parsing.
  """
  @spec parse(binary(), [parse_opt()]) :: ZWave.node_id()
  def parse(node_id_binary, opts \\ [])

  def parse(<<node_id>>, _opts), do: node_id

  def parse(node_id_bin, opts) do
    case Keyword.get(opts, :delimiter_size, 0) do
      0 ->
        do_parse(node_id_bin)

      del_size ->
        <<node_id_8, _delimiter::size(del_size)-unit(8), node_id_16::binary>> = node_id_bin
        do_parse(<<node_id_8, node_id_16::binary>>)
    end
  end

  defp do_parse(<<node_id>>), do: node_id
  defp do_parse(<<@node_id_is_16_bit, node_id::16>>), do: node_id
  defp do_parse(<<node_id, _ignored::16>>), do: node_id
end
