defmodule Grizzly.ZWave.Commands.ZipInverseNodeSolicitation do
  @moduledoc """
  Used to resolve a NodeID (link-layer address) of a Z-Wave node to an IPv6 address of that node in its actual Z-Wave HAN / IP subnet.

  Params:

    * `:node_id` - The NodeID that is to be resolved to an IPv6 address (required)

    * `:local` - The flag indicates that the requester would like to receive the site-local address (a.k.a. ULA) even if a
                 global address exists (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipND

  @type param :: {:node_id, byte} | {:local, boolean}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_inverse_node_solicitation,
      command_byte: 0x04,
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
    <<0x00::size(4), local_bit::size(1), 0x00::size(3), node_id>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved::size(4), local_bit::size(1), _also_reserved::size(3), node_id>>) do
    {:ok, [node_id: node_id, local: local_bit == 0x01]}
  end
end
