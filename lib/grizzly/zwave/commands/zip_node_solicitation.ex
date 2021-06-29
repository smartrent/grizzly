defmodule Grizzly.ZWave.Commands.ZipNodeSolicitation do
  @moduledoc """
  This command is used to resolve an IPv6 address of a Z-Wave node to the NodeID
  of that node.

  Params:

    * `:ipv6_address` - The IPv6 address of a node (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZipND

  @type param :: {:ipv6_address, ZipND.ipv6()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zip_node_solicitation,
      command_byte: 0x03,
      command_class: ZipND,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    ipv6_address_binary = Command.param!(command, :ipv6_address) |> ZipND.encode_ipv6_address()

    <<0x00, 0x00>> <> ipv6_address_binary
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved, 0x00, ipv6_binary::binary-size(16)>>) do
    with {:ok, ipv6_address} <- ZipND.decode_ipv6_address(ipv6_binary) do
      {:ok, [ipv6_address: ipv6_address]}
    else
      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :zip_node_solicitation}}
    end
  end
end
