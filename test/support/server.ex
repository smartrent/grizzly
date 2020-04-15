defmodule GrizzlyTest.Server do
  use GenServer

  alias Grizzly.SeqNumber
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    ZIPPacket,
    NodeListReport,
    SwitchBinaryReport,
    NodeAddDSKReport,
    NodeAddStatus,
    NodeAddKeysReport,
    NodeRemoveStatus
  }

  def start(port) do
    GenServer.start(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])
    {:ok, %{socket: socket}}
  end

  def handle_info({:udp, _port, _ip, return_port, msg}, state) when return_port > 5000 do
    node_id = return_port - 5000
    {:ok, zip_packet} = ZIPPacket.from_binary(msg)

    case node_id do
      # ignore all commands
      100 ->
        :ok

      # nack response only
      101 ->
        send_nack_response(state.socket, return_port, zip_packet)

      # mark as sleeping node
      102 ->
        send_nack_waiting(state.socket, return_port, zip_packet)

      # Node 301 is a long waiting inclusion meant to exercising stopping inclusion/exclusion
      301 ->
        send_ack_response(state.socket, return_port, zip_packet)
        only_send_report_for_node_add_or_remove_stop(state.socket, return_port, zip_packet)

      # this controller id is for testing happy S2 inclusion
      302 ->
        send_ack_response(state.socket, return_port, zip_packet)
        handle_inclusion_packet(state.socket, return_port, zip_packet)
        :ok

      # this controller id is for testing sad S2 inclusion
      303 ->
        :ok

      # async ignore all
      400 ->
        :ok

      _rest ->
        send_ack_response(state.socket, return_port, zip_packet)
        maybe_send_a_report(state.socket, return_port, zip_packet)
    end

    {:noreply, state}
  end

  defp send_ack_response(socket, port, incoming_zip_packet) do
    out_packet = ZIPPacket.make_ack_response(incoming_zip_packet.seq_number)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZIPPacket.to_binary(out_packet)
    )
  end

  def only_send_report_for_node_add_or_remove_stop(socket, port, zip_packet) do
    command = zip_packet.command

    case get_node_add_remove_command(command, zip_packet) do
      {:ok, status_failed} ->
        seq_number = SeqNumber.get_and_inc()

        out_packet =
          ZIPPacket.with_zwave_command(status_failed, flag: nil, seq_number: seq_number)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZIPPacket.to_binary(out_packet)
        )

      _ ->
        :ok
    end
  end

  defp get_node_add_remove_command(%Command{name: :node_add} = command, zip_packet) do
    if Command.param!(command, :mode) == :node_add_stop do
      NodeAddStatus.new(
        seq_number: zip_packet.seq_number,
        node_id: 15,
        status: :failed,
        listening?: true,
        basic_device_class: 0x10,
        generic_device_class: 0x12,
        specific_device_class: 0x15,
        command_classes: [0x34],
        secure_command_classes: []
      )
    end
  end

  defp get_node_add_remove_command(%Command{name: :node_remove} = command, zip_packet) do
    if Command.param!(command, :mode) == :remove_node_stop do
      NodeRemoveStatus.new(
        seq_number: zip_packet.seq_number,
        node_id: 15,
        status: :failed
      )
    end
  end

  defp send_nack_response(socket, port, incoming_zip_packet) do
    out_packet = ZIPPacket.make_nack_response(incoming_zip_packet.seq_number)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZIPPacket.to_binary(out_packet)
    )
  end

  defp send_nack_waiting(socket, port, incoming_zip_packet) do
    out_packet = ZIPPacket.make_nack_waiting_response(2, incoming_zip_packet.seq_number)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZIPPacket.to_binary(out_packet)
    )
  end

  defp maybe_send_a_report(socket, port, zip_packet) do
    if expects_a_report(zip_packet.command.name) do
      out_packet = build_report(zip_packet)

      :gen_udp.send(
        socket,
        {0, 0, 0, 0},
        port,
        ZIPPacket.to_binary(out_packet)
      )
    else
      :ok
    end
  end

  def handle_inclusion_packet(socket, port, incoming_zip_packet) do
    case incoming_zip_packet.command.name do
      :node_add ->
        send_node_add_keys_report(socket, port, incoming_zip_packet)

      :node_add_keys_set ->
        send_add_node_dsk_report(socket, port, incoming_zip_packet)

      :node_add_dsk_set ->
        {:ok, command} = build_s2_node_add_status(incoming_zip_packet)

        out_zip_packet =
          ZIPPacket.with_zwave_command(command, seq_number: SeqNumber.get_and_inc())

        :gen_udp.send(socket, {0, 0, 0, 0}, port, ZIPPacket.to_binary(out_zip_packet))
    end
  end

  def send_node_add_keys_report(socket, port, incoming_zip_packet) do
    {:ok, keys_report} =
      NodeAddKeysReport.new(
        csa: false,
        requested_keys: [:s2_unauthenticated, :s2_authenticated],
        seq_number: incoming_zip_packet.seq_number
      )

    out_zip_packet =
      ZIPPacket.with_zwave_command(keys_report, seq_number: SeqNumber.get_and_inc())

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZIPPacket.to_binary(out_zip_packet)
    )
  end

  def send_add_node_dsk_report(socket, port, incoming_zip_packet) do
    case Command.param!(incoming_zip_packet.command, :granted_keys) do
      [:s2_unauthenticated] ->
        seq_number = SeqNumber.get_and_inc()

        {:ok, dsk_report} =
          NodeAddDSKReport.new(
            seq_number: seq_number,
            input_dsk_length: 0,
            dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
          )

        out_zip_packet = ZIPPacket.with_zwave_command(dsk_report, seq_number: seq_number)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZIPPacket.to_binary(out_zip_packet)
        )

      [:s2_authenticated] ->
        seq_number = SeqNumber.get_and_inc()

        {:ok, dsk_report} =
          NodeAddDSKReport.new(
            seq_number: seq_number,
            input_dsk_length: 2,
            dsk: "00000-18819-09924-30691-15973-33711-04005-03623"
          )

        out_zip_packet = ZIPPacket.with_zwave_command(dsk_report, seq_number: seq_number)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZIPPacket.to_binary(out_zip_packet)
        )
    end
  end

  defp expects_a_report(:switch_binary_get), do: true
  defp expects_a_report(:node_add), do: true
  defp expects_a_report(:node_remove), do: true
  defp expects_a_report(:node_list_get), do: true
  defp expects_a_report(_), do: false

  defp build_report(zip_packet) do
    {:ok, report} = do_build_report(zip_packet.command.name, zip_packet)
    seq_number = SeqNumber.get_and_inc()

    ZIPPacket.with_zwave_command(report, flag: nil, seq_number: seq_number)
  end

  defp do_build_report(:node_list_get, zip_packet) do
    NodeListReport.new(
      status: :latest,
      seq_number: zip_packet.seq_number,
      node_ids: [1, 2, 3, 4, 5, 100, 101, 102],
      controller_id: 1
    )
  end

  defp do_build_report(:node_add, zip_packet) do
    NodeAddStatus.new(
      seq_number: zip_packet.seq_number,
      node_id: 15,
      status: :done,
      listening?: true,
      basic_device_class: 0x10,
      generic_device_class: 0x12,
      specific_device_class: 0x15,
      command_classes: [0x34],
      secure_command_classes: []
    )
  end

  defp do_build_report(:node_remove, zip_packet) do
    NodeRemoveStatus.new(
      seq_number: zip_packet.seq_number,
      node_id: 15,
      status: :done
    )
  end

  defp do_build_report(:switch_binary_get, _) do
    SwitchBinaryReport.new(target_value: :off)
  end

  defp build_s2_node_add_status(zip_packet) do
    case Command.param!(zip_packet.command, :input_dsk_length) do
      0 ->
        NodeAddStatus.new(
          seq_number: zip_packet.seq_number,
          node_id: 15,
          status: :done,
          listening?: true,
          basic_device_class: 0x10,
          generic_device_class: 0x12,
          specific_device_class: 0x15,
          command_classes: [0x34],
          secure_command_classes: [],
          keys_granted: [:s2_unauthenticated],
          kex_fail_type: :none
        )

      2 ->
        NodeAddStatus.new(
          seq_number: zip_packet.seq_number,
          node_id: 15,
          status: :done,
          listening?: true,
          basic_device_class: 0x10,
          generic_device_class: 0x12,
          specific_device_class: 0x15,
          command_classes: [0x34],
          secure_command_classes: [],
          keys_granted: [:s2_authenticated],
          kex_fail_type: :none
        )
    end
  end
end
