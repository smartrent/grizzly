defmodule Grizzly.Test.Server do
  use GenServer

  alias Grizzly.Test.TestProto

  def start(port) do
    GenServer.start(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])
    {:ok, socket}
  end

  def handle_info(
        {:udp, _port, _ip, return_port, <<0x00, 0x00, 0x00, 0x00, msg::binary>>},
        socket
      ) do
    case msg do
      <<0x01, seq_number, echo_value>> ->
        reply(socket, return_port, TestProto.echo_response(echo_value, seq_number))
    end

    {:noreply, socket}
  end

  # def handle_info({:udp, _port, _ip, return_port, msg}, socket) do
  #   _ =
  #     case handle_request(msg) do
  #       res when is_list(res) ->
  #         res
  #         |> Enum.each(fn r ->
  #           _ = reply(socket, return_port, r)
  #           :timer.sleep(500)
  #         end)

  #       res ->
  #         reply(socket, return_port, res)
  #     end

  #   {:noreply, socket}
  # end

  def reply(socket, port, msg) do
    :gen_udp.send(socket, {0, 0, 0, 0}, port, msg)
  end

  # defp handle_request(<<0x23, 0x03, 0x80>>) do
  #   <<0x23, 0x03, 0x40>>
  # end

  # defp handle_request(msg) do
  #   msg
  #   |> Packet.decode()
  #   |> Packet.log()
  #   |> process_packet()
  # end

  # def process_packet(%Packet{
  #       seq_number: seq_number,
  #       body: %{command_class: :switch_binary, command: :set}
  #     }) do
  #   <<35, 2, 64, 144, seq_number, 0, 0, 30, 3, 27, 0, 1, 0, 1, 2, 0, 5, 2, 5, 0, 0, 0, 0, 3, 3, 5,
  #     188, 127, 127, 127, 127, 4, 1, 0, 5, 1, 0>>
  # end

  # def process_packet(%Packet{
  #       seq_number: seq_number,
  #       body: %{command_class: :switch_binary, command: :get}
  #     }) do
  #   [
  #     <<35, 2, 64, 144, seq_number, 0, 0, 30, 3, 27, 0, 1, 0, 1, 2, 0, 6, 2, 5, 0, 0, 0, 0, 3, 3,
  #       5, 188, 127, 127, 127, 127, 4, 1, 0, 5, 1, 0>>,
  #     <<35, 2, 0, 192, 112, 0, 0, 5, 132, 2, 0, 0, 37, 3, 255>>
  #   ]
  # end

  # def process_packet(%Packet{
  #       seq_number: seq_number,
  #       body: %{command_class: :battery, command: :get}
  #     }) do
  #   [
  #     <<35, 2, 64, 144, seq_number, 0, 0, 30, 3, 27, 0, 1, 0, 1, 2, 4, 230, 2, 5, 0, 0, 0, 0, 2,
  #       3, 5, 202, 127, 127, 127, 127, 4, 1, 0, 5, 1, 1>>,
  #     <<35, 2, 0, 192, 135, 0, 0, 5, 132, 2, 0, 0, 128, 3, 90>>
  #   ]
  # end

  # def process_packet(%Packet{body: %{command_class: :zip_nd, node_id: node_id}}) do
  #   <<88, 1, 0, node_id, 253, 0, 187, 187, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, node_id, 207, 59, 74,
  #     228>>
  # end

  # def process_packet(%Packet{
  #       body: %{command: :node_list_get, command_class: :network_management_proxy},
  #       seq_number: seq_number
  #     }) do
  #   [
  #     <<35, 2, 64, 0, seq_number, 0, 0>>,
  #     <<35, 2, 0, 208, 152, 0, 0, 5, 132, 2, 4, 0, 82, 2, seq_number, 0, 1, 1, 0, 0, 0, 0, 0, 0,
  #       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  #   ]
  # end

  # def process_packet(%Packet{
  #       body: %{
  #         command: :node_info_cache,
  #         command_class: :network_management_proxy,
  #         value: <<_, 1, _node_id>>
  #       },
  #       seq_number: seq_number
  #     }) do
  #   [
  #     <<35, 2, 64, 0, seq_number, 0, 0>>,
  #     <<35, 2, 0, 208, 11, 0, 0, 5, 132, 2, 4, 0, 82, 4, seq_number, 0, 211, 156, 0, 4, 16, 1, 94,
  #       114, 134, 133, 92, 89, 90, 115, 112, 37, 39, 113, 50, 32, 104, 35>>
  #   ]
  # end

  # def process_packet(%Packet{
  #       body: %{
  #         command: :set,
  #         command_class: :association
  #       },
  #       seq_number: seq_number
  #     }) do
  #   [
  #     <<35, 2, 48, 144, seq_number, 0, 0, 22, 1, 3, 0, 0, 1, 3, 14, 0, 1, 1, 1, 2, 0, 5, 2, 5, 0,
  #       0, 0, 0, 0>>,
  #     <<35, 2, 64, 144, seq_number, 0, 0, 30, 3, 27, 0, 1, 1, 1, 2, 4, 169, 2, 5, 0, 0, 0, 0, 2,
  #       3, 5, 201, 127, 127, 127, 127, 4, 1, 0, 5, 1, 1>>
  #   ]
  # end

  # def process_packet(%Packet{
  #       body: %{command: :manufacturer_specific_get, command_class: :manufacturer_specific},
  #       seq_number: seq_no
  #     }) do
  #   [
  #     <<35, 2, 48, 144, seq_no, 0, 0, 22, 1, 3, 0, 0, 1, 3, 14, 0, 1, 0, 1, 2, 5, 5, 2, 5, 0, 0,
  #       0, 0, 2>>,
  #     <<35, 2, 64, 144, seq_no, 0, 0, 30, 3, 27, 0, 1, 0, 1, 2, 4, 201, 2, 5, 0, 0, 0, 0, 2, 3, 5,
  #       202, 127, 127, 127, 127, 4, 1, 0, 5, 1, 1>>,
  #     <<35, 2, 0, 192, 29, 0, 0, 5, 132, 2, 0, 0, 114, 5, 1, 79, 84, 66, 84, 54>>
  #   ]
  # end
end
