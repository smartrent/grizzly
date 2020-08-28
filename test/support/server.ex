defmodule GrizzlyTest.Server do
  use GenServer

  alias Grizzly.SeqNumber
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    ZIPPacket,
    ZIPKeepAlive,
    NodeListReport,
    SwitchBinaryReport,
    NodeAddDSKReport,
    NodeAddStatus,
    NodeAddKeysReport,
    NodeRemoveStatus,
    FirmwareUpdateMDRequestReport,
    FirmwareUpdateMDGet,
    FirmwareUpdateMDStatusReport
  }

  require Logger

  def start(port) do
    GenServer.start(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])
    {:ok, %{socket: socket}}
  end

  def handle_info({:udp, _port, _ip, return_port, msg}, state) when return_port > 5000 do
    node_id = return_port - 5000
    {:ok, zip_packet} = ZWave.from_binary(msg)

    if zip_packet.name == :keep_alive do
      handle_keep_alive(state.socket, return_port, zip_packet)
    else
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

        # Node 201 is for testing starting a firmware update and uploading an image
        201 ->
          send_ack_response(state.socket, return_port, zip_packet)
          maybe_send_a_report(state.socket, return_port, zip_packet)
          # the device asks for image fragments
          send_firmware_update_md_get_command(state.socket, return_port,
            number_of_reports: 1,
            # Change this to be the last fragment
            report_number: 1
          )

        202 ->
          send_ack_response(state.socket, return_port, zip_packet)
          maybe_send_a_report(state.socket, return_port, zip_packet)
          # the device asks for image fragments
          send_firmware_update_md_get_command(state.socket, return_port,
            number_of_reports: 2,
            # change this to the before last fragment
            report_number: 1
            # TODO only expect an update status report on the last fragment
          )

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
    end

    {:noreply, state}
  end

  defp send_ack_response(socket, port, incoming_zip_packet) do
    seq_number = Command.param!(incoming_zip_packet, :seq_number)
    out_packet = ZIPPacket.make_ack_response(seq_number)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZWave.to_binary(out_packet)
    )
  end

  def only_send_report_for_node_add_or_remove_stop(socket, port, zip_packet) do
    command = Command.param!(zip_packet, :command)

    case get_node_add_remove_command(command, zip_packet) do
      {:ok, status_failed} ->
        seq_number = SeqNumber.get_and_inc()

        {:ok, out_packet} = ZIPPacket.with_zwave_command(status_failed, seq_number, flag: nil)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZWave.to_binary(out_packet)
        )

      _ ->
        :ok
    end
  end

  defp get_node_add_remove_command(%Command{name: :node_add} = command, zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)

    if Command.param!(command, :mode) == :node_add_stop do
      NodeAddStatus.new(
        seq_number: seq_number,
        node_id: 15,
        status: :failed,
        listening?: true,
        basic_device_class: 0x10,
        generic_device_class: 0x12,
        specific_device_class: 0x15,
        command_classes: [0x34]
      )
    end
  end

  defp get_node_add_remove_command(%Command{name: :node_remove} = command, zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)

    if Command.param!(command, :mode) == :remove_node_stop do
      NodeRemoveStatus.new(
        seq_number: seq_number,
        node_id: 15,
        status: :failed
      )
    end
  end

  defp send_nack_response(socket, port, incoming_zip_packet) do
    seq_number = Command.param!(incoming_zip_packet, :seq_number)
    out_packet = ZIPPacket.make_nack_response(seq_number)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZWave.to_binary(out_packet)
    )
  end

  defp send_nack_waiting(socket, port, incoming_zip_packet) do
    seq_number = Command.param!(incoming_zip_packet, :seq_number)
    out_packet = ZIPPacket.make_nack_waiting_response(seq_number, 2)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZWave.to_binary(out_packet)
    )

    spawn(fn ->
      Process.sleep(2_000)
      maybe_send_a_report(socket, port, incoming_zip_packet)
    end)
  end

  defp handle_keep_alive(socket, port, keep_alive) do
    if Command.param!(keep_alive, :ack_flag) == :ack_request do
      {:ok, response} = ZIPKeepAlive.new(ack_flag: :ack_response)

      :gen_udp.send(socket, {0, 0, 0, 0}, port, ZWave.to_binary(response))
    end
  end

  defp maybe_send_a_report(socket, port, zip_packet) do
    if Command.param!(zip_packet, :flag) != :ack_response do
      encapsulated_command = Command.param!(zip_packet, :command)

      if expects_a_report(encapsulated_command.name) do
        {:ok, out_packet} = build_report(zip_packet)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZWave.to_binary(out_packet)
        )
      else
        :ok
      end
    else
      :ok
    end
  end

  defp send_firmware_update_md_get_command(socket, port,
         number_of_reports: number_of_reports,
         report_number: report_number
       ) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      FirmwareUpdateMDGet.new(number_of_reports: number_of_reports, report_number: report_number)

    {:ok, out_packet} = ZIPPacket.with_zwave_command(command, seq_number, flag: nil)

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZWave.to_binary(out_packet)
    )
  end

  def handle_inclusion_packet(socket, port, incoming_zip_packet) do
    encapsulated_command = Command.param!(incoming_zip_packet, :command)

    case encapsulated_command.name do
      :node_add ->
        send_node_add_keys_report(socket, port, incoming_zip_packet)

      :node_add_keys_set ->
        send_add_node_dsk_report(socket, port, incoming_zip_packet)

      :node_add_dsk_set ->
        {:ok, command} = build_s2_node_add_status(incoming_zip_packet)

        {:ok, out_zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc())

        :gen_udp.send(socket, {0, 0, 0, 0}, port, ZWave.to_binary(out_zip_packet))
    end
  end

  def send_node_add_keys_report(socket, port, incoming_zip_packet) do
    seq_number = Command.param!(incoming_zip_packet, :seq_number)

    {:ok, keys_report} =
      NodeAddKeysReport.new(
        csa: false,
        requested_keys: [:s2_unauthenticated, :s2_authenticated],
        seq_number: seq_number
      )

    {:ok, out_zip_packet} = ZIPPacket.with_zwave_command(keys_report, SeqNumber.get_and_inc())

    :gen_udp.send(
      socket,
      {0, 0, 0, 0},
      port,
      ZWave.to_binary(out_zip_packet)
    )
  end

  def send_add_node_dsk_report(socket, port, incoming_zip_packet) do
    command = Command.param!(incoming_zip_packet, :command)

    case Command.param!(command, :granted_keys) do
      [:s2_unauthenticated] ->
        seq_number = SeqNumber.get_and_inc()

        {:ok, dsk_report} =
          NodeAddDSKReport.new(
            seq_number: seq_number,
            input_dsk_length: 0,
            dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
          )

        {:ok, out_zip_packet} = ZIPPacket.with_zwave_command(dsk_report, seq_number)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZWave.to_binary(out_zip_packet)
        )

      [:s2_authenticated] ->
        seq_number = SeqNumber.get_and_inc()

        {:ok, dsk_report} =
          NodeAddDSKReport.new(
            seq_number: seq_number,
            input_dsk_length: 2,
            dsk: "00000-18819-09924-30691-15973-33711-04005-03623"
          )

        {:ok, out_zip_packet} = ZIPPacket.with_zwave_command(dsk_report, seq_number)

        :gen_udp.send(
          socket,
          {0, 0, 0, 0},
          port,
          ZWave.to_binary(out_zip_packet)
        )
    end
  end

  defp expects_a_report(nil), do: false
  defp expects_a_report(:switch_binary_get), do: true
  defp expects_a_report(:node_add), do: true
  defp expects_a_report(:node_remove), do: true
  defp expects_a_report(:node_list_get), do: true
  defp expects_a_report(:firmware_update_md_request_get), do: true
  defp expects_a_report(:firmware_update_md_report), do: true

  defp expects_a_report(_), do: false

  defp build_report(zip_packet) do
    encapsulated_command = Command.param!(zip_packet, :command)
    {:ok, report} = do_build_report(encapsulated_command.name, zip_packet)
    seq_number = SeqNumber.get_and_inc()

    ZIPPacket.with_zwave_command(report, seq_number, flag: flag_for_report(report))
  end

  defp do_build_report(:node_list_get, zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)

    NodeListReport.new(
      status: :latest,
      seq_number: seq_number,
      node_ids: [1, 2, 3, 4, 5, 100, 101, 102],
      controller_id: 1
    )
  end

  defp do_build_report(:node_add, zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)

    command_classes = [
      non_secure_supported: [:basic, :meter],
      non_secure_controlled: [],
      secure_supported: [:alarm, :switch_binary],
      secure_controlled: [:door_lock, :user_code]
    ]

    NodeAddStatus.new(
      seq_number: seq_number,
      node_id: 15,
      status: :done,
      listening?: true,
      basic_device_class: 0x10,
      generic_device_class: 0x12,
      specific_device_class: 0x15,
      command_classes: command_classes
    )
  end

  defp do_build_report(:node_remove, zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)

    NodeRemoveStatus.new(
      seq_number: seq_number,
      node_id: 15,
      status: :done
    )
  end

  defp do_build_report(:firmware_update_md_request_get, _zip_packet) do
    FirmwareUpdateMDRequestReport.new(status: :ok)
  end

  defp do_build_report(:firmware_update_md_report, _zip_packet) do
    FirmwareUpdateMDStatusReport.new(
      status: :successful_restarting,
      wait_time: 5
    )
  end

  defp do_build_report(:switch_binary_get, _) do
    SwitchBinaryReport.new(target_value: :off)
  end

  defp build_s2_node_add_status(zip_packet) do
    encapsulated_command = Command.param!(zip_packet, :command)
    seq_number = Command.param!(zip_packet, :seq_number)

    command_classes = [
      non_secure_supported: [:basic, :meter],
      non_secure_controlled: [],
      secure_supported: [:alarm, :switch_binary],
      secure_controlled: [:door_lock, :user_code]
    ]

    case Command.param!(encapsulated_command, :input_dsk_length) do
      0 ->
        NodeAddStatus.new(
          seq_number: seq_number,
          node_id: 15,
          status: :done,
          listening?: true,
          basic_device_class: 0x10,
          generic_device_class: 0x12,
          specific_device_class: 0x15,
          command_classes: command_classes,
          keys_granted: [:s2_unauthenticated],
          kex_fail_type: :none
        )

      2 ->
        NodeAddStatus.new(
          seq_number: seq_number,
          node_id: 15,
          status: :done,
          listening?: true,
          basic_device_class: 0x10,
          generic_device_class: 0x12,
          specific_device_class: 0x15,
          command_classes: command_classes,
          keys_granted: [:s2_authenticated],
          kex_fail_type: :none
        )
    end
  end

  defp flag_for_report(%Command{name: :switch_binary_report}) do
    :ack_request
  end

  defp flag_for_report(_) do
    nil
  end
end
