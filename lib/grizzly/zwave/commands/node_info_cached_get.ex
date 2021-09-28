defmodule Grizzly.ZWave.Commands.NodeInfoCachedGet do
  @moduledoc """
  Get the node information that is cached on another device

  This is useful for getting the command classes and device classes

  When sending this command the Z-Wave network should send back a
  `NodeInfoCachedReport` command.

  Params:
    `:seq_number` - the sequence number for the networked command (required)
    `:max_age` - the max age of the node info frame give in 2^n minutes
     see section on cached minutes below for more information (optional)
    `:node_id` - the node id that that node information is being requested for
    (required)

  ## Cached Minutes

  This Z-Wave network will cache node information to perverse bandwidth and
  provides access to node information about sleeping nodes.

  When sending the `NodeInfoCachedGet` command we can specify the max age of
  the cached data. If the cached data is older than the `:max_age` param the
  Z-Wave network will try to refresh the cache and send back the most updated
  information.

  The values for the `:max_age` parameter are numbers from 1 to 14. This number
  will be 2 ^ number minutes. So if you pass the number `4` the receiving
  Z-Wave device will consider that 16 minutes.

  Two other options are `:infinite` and `:force_update`. Where `:infinite`
  means that the cache will not be freshed regardless of how old the data is
  and where `:force_update` means that no matter the age of the cached node
  data the cache will attempt to be updated.

  We default to `10` which `1024` minutes, or just a little over 1 day. This
  default is chosen to limit bandwidth usage. Also, the data found in the
  report is fairly static, so there isn't a pressing need to update the cache
  to often.
  """

  @behaviour Grizzly.ZWave.Command

  # For version 4 of this command, if the node id is a 16 bit node ID we set the
  # the node id byte in the binary to `0xFF` as per the specification.
  #
  # In ZWA_Z-Wave Network Protocol Command Class Specification 12.0.0.pdf:
  #
  # Section 4.5.7.3
  #  "The value 0xFF MUST indicate that the queried NodeID is indicated in the Extended NodeID field"
  @node_id_is_16_bit 0xFF

  @type max_age() :: 1..14 | :infinite | :force_update

  @type param() ::
          {:seq_number, Grizzly.seq_number()}
          | {:node_id, Grizzly.ZWave.node_id()}
          | {:max_age, max_age()}

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    params = set_defaults(params)
    # TODO: validate params
    command = %Command{
      name: :node_info_cache_get,
      command_byte: 0x03,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t(), keyword()) :: binary()
  def encode_params(command, opts \\ []) do
    seq_number = Command.param!(command, :seq_number)
    max_age = Command.param!(command, :max_age)
    node_id = Command.param!(command, :node_id)

    case Keyword.get(opts, :command_class_version, 4) do
      4 ->
        <<seq_number, encode_max_age(max_age), encode_node_id_v4(node_id)::binary>>

      v when v < 4 ->
        <<seq_number, encode_max_age(max_age), node_id>>
    end
  end

  defp encode_node_id_v4(node_id) when node_id < 233, do: <<node_id, 0x00::16>>

  defp encode_node_id_v4(node_id) when node_id > 255 and node_id <= 65535,
    do: <<@node_id_is_16_bit, node_id::16>>

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(params_binary) do
    <<seq_number, max_age_byte, node_id_bin::binary>> = params_binary
    node_id = parse_node_id_bin(node_id_bin)

    case decode_max_age(max_age_byte) do
      {:ok, max_age} ->
        {:ok, [seq_number: seq_number, max_age: max_age, node_id: node_id]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp parse_node_id_bin(<<node_id>>), do: node_id
  defp parse_node_id_bin(<<@node_id_is_16_bit, node_id::16>>), do: node_id
  defp parse_node_id_bin(<<node_id, _rest::16>>), do: node_id

  @spec encode_max_age(max_age()) :: 0..15
  def encode_max_age(n) when n > 0 and n < 15, do: n
  def encode_max_age(:infinite), do: 15
  def encode_max_age(:force_update), do: 0

  @spec decode_max_age(byte()) :: {:ok, max_age()} | {:error, DecodeError.t()}
  def decode_max_age(0), do: {:ok, :force_update}
  def decode_max_age(15), do: {:ok, :infinite}
  def decode_max_age(n) when n > 0 and n < 15, do: {:ok, n}

  def decode_max_age(n),
    do: {:error, %DecodeError{value: n, param: :max_age, command: :node_info_cache_get}}

  defp set_defaults(params) do
    Keyword.put_new(params, :max_age, 10)
  end
end
