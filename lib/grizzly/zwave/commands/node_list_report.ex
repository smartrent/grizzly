defmodule Grizzly.ZWave.Commands.NodeListReport do
  @moduledoc """
  The NODE_LIST_REPORT command
  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @impl true
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :node_list_report,
      command_byte: 0x02,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_ids = encode_node_ids(Command.param!(command, :node_ids))
    status = encode_status(Command.param!(command, :status))
    controller_id = encode_controller_id(Command.param!(command, :controller_id))

    <<seq_number, status, controller_id>> <> node_ids
  end

  @impl true
  def decode_params(<<seq_number, status, controller_id, node_ids::binary>>) do
    case decode_status(status) do
      {:ok, status} ->
        controller_id = decode_controller_id(controller_id)
        node_ids = decode_node_ids(node_ids)

        {:ok,
         [
           seq_number: seq_number,
           controller_id: controller_id,
           status: status,
           node_ids: node_ids
         ]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def encode_node_ids(node_ids) do
    mask_bit = node_id_mask(node_ids)
    <<mask_bit::little-integer-size(29)-unit(8)>>
  end

  def decode_node_ids(node_ids) do
    unmask(node_ids)
  end

  def encode_status(:latest), do: 0x00
  def encode_status(:outdated), do: 0x01

  def decode_status(0x00), do: {:ok, :latest}
  def decode_status(0x01), do: {:ok, :outdated}

  def decode_status(byte),
    do: {:error, %DecodeError{value: byte, param: :status, command: :node_list_report}}

  def encode_controller_id(:unknown), do: 0x00
  def encode_controller_id(byte), do: byte

  def decode_controller_id(0x00), do: :unknown
  def decode_controller_id(controller_id), do: controller_id

  defp node_id_mask(node_ids) do
    Enum.reduce(node_ids, 0, fn node_id, mask ->
      mask_bit = 0 ||| 1 <<< (node_id - 1)
      mask ||| mask_bit
    end)
  end

  defp unmask(mask) do
    unmask(0, [], mask)
  end

  defp unmask(_, xs, <<>>), do: Enum.sort(xs)

  defp unmask(offset, xs, <<byte::binary-size(1), rest::binary>>) do
    xs = Enum.concat(xs, get_digits(offset, byte))
    unmask(offset + 8, xs, rest)
  end

  defp get_digits(_, <<0>>), do: []

  defp get_digits(offset, byte) do
    Enum.reduce(
      1..8,
      [],
      fn position, acc ->
        case bit_at?(position, byte) do
          true -> [position + offset | acc]
          false -> acc
        end
      end
    )
  end

  defp bit_at?(position, <<byte>>) do
    (1 <<<
       (position - 1) &&& byte) != 0
  end
end
