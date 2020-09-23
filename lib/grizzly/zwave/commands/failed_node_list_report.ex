defmodule Grizzly.ZWave.Commands.FailedNodeListReport do
  @moduledoc """
  This command is used to advertise the current list of failing nodes in the network.

  Params:

    * `:seq_number` - Sequence number
    * `:node_ids` - The ids of all nodes in the network found to be unresponsive

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @type param :: {:node_ids, [ZWave.node_id()]} | {:seq_number, ZWave.seq_number()}

  @impl true
  def new(params) do
    command = %Command{
      name: :failed_node_list_report,
      command_byte: 0x0C,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_ids = Command.param!(command, :node_ids)
    node_id_bytes = node_ids_to_bytes(node_ids)
    <<seq_number>> <> node_id_bytes
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, node_id_bytes::binary>>) do
    node_ids = node_ids_from_bytes(node_id_bytes)
    {:ok, [seq_number: seq_number, node_ids: node_ids]}
  end

  defp node_ids_to_bytes(node_ids) do
    bytes =
      for byte_index <- 0..28 do
        for bit_index <- 8..1, into: <<>> do
          node_id = byte_index * 8 + bit_index
          if node_id in node_ids, do: <<1::size(1)>>, else: <<0::size(1)>>
        end
      end

    for byte <- bytes, into: <<>>, do: byte
  end

  defp node_ids_from_bytes(binary) do
    :erlang.binary_to_list(binary)
    |> Enum.with_index()
    |> Enum.reduce(
      [],
      fn {byte, byte_index}, acc ->
        bit_list = for <<(bit::size(1) <- <<byte>>)>>, do: bit

        id_or_nil_list =
          for bit_index <- 0..7 do
            bit = Enum.at(bit_list, 7 - bit_index)
            if bit == 1, do: byte_index * 8 + bit_index + 1, else: nil
          end

        acc ++ Enum.reject(id_or_nil_list, &(&1 == nil))
      end
    )
  end
end
