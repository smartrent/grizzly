defmodule Grizzly.Client.DTLS.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Client.DTLS
  alias Grizzly.Packet
  alias Grizzly.Packet.HeaderExtension.EncapsulationFormatInfo

  test "handles response from heart beat" do
    heart_beat_response =
      [0x23, 0x03, 0x40]
      |> make_dtls_message()

    assert {:ok, :heart_beat} = DTLS.parse_response(heart_beat_response)
  end

  describe "Handling adding a node" do
    test "ack response packet is parsed" do
      node_add_res1 =
        [0x23, 0x2, 0x40, 0x00, 0x01, 0x00, 0x00]
        |> make_dtls_message()

      assert {:ok, %Packet{types: [:ack_response]}} = DTLS.parse_response(node_add_res1)
    end

    test "node add report is parsed" do
      node_add_report_done =
        [
          0x23,
          0x02,
          0x00,
          0xD0,
          0x04,
          0x00,
          0x00,
          0x05,
          0x84,
          0x02,
          0x04,
          0x00,
          0x34,
          0x02,
          0x01,
          0x06,
          0x00,
          0x06,
          0x14,
          0xD3,
          0x9C,
          0x04,
          0x11,
          0x01,
          0x5E,
          0x86,
          0x72,
          0x5A,
          0x85,
          0x5C,
          0x59,
          0x73,
          0x26,
          0x27,
          0x70,
          0x7A,
          0x68,
          0x23,
          0x00,
          0x00,
          0x00
        ]
        |> make_dtls_message()

      body = %{
        command_class: :network_management_inclusion,
        command: :node_add_status,
        seq_no: 0x01,
        status: :done,
        listening?: true,
        node_id: 0x06,
        basic_class: :routing_slave,
        generic_class: :switch_multilevel,
        specific_class: :power_switch_multilevel,
        command_classes: [
          :zwaveplus_info,
          :command_class_version,
          :manufacturer_specific,
          :device_rest_locally,
          :association,
          :ip_association,
          :association_group_info,
          :powerlevel,
          :switch_multilevel,
          :switch_all,
          :configuration,
          :firmware_update_md,
          :zip_naming,
          :zip
        ],
        secure: false,
        dsk: "",
        keys_granted: [],
        dsk_length: 0x00,
        kex_fail_type: :none
      }

      packet = %Packet{
        types: [],
        seq_number: 1,
        body: body,
        header_extensions: [EncapsulationFormatInfo.new(:s2_access_control, false)]
      }

      assert {:ok, packet} == DTLS.parse_response(node_add_report_done)
    end
  end

  describe "handle removing a node" do
    test "parses node remove report command" do
      node_remove_report_done =
        [
          0x23,
          0x02,
          0x00,
          0xD0,
          0x07,
          0x00,
          0x00,
          0x05,
          0x84,
          0x02,
          0x04,
          0x00,
          0x34,
          0x04,
          0x01,
          0x06,
          0x0A
        ]
        |> make_dtls_message()

      body = %{
        command_class: :network_management_inclusion,
        command: :node_remove_status,
        seq_no: 0x01,
        status: :done,
        node_id: 0x0A
      }

      packet = %Packet{
        types: [],
        seq_number: 0x01,
        body: body,
        header_extensions: [EncapsulationFormatInfo.new(:s2_access_control, false)]
      }

      assert {:ok, packet} == DTLS.parse_response(node_remove_report_done)
    end
  end

  defp make_dtls_message(packet) do
    {:ssl, {:sslsocket, {:gen_udp, :port, :dtls_connection}, :pid}, packet}
  end
end
