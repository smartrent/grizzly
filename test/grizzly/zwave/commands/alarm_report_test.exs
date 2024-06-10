defmodule Grizzly.ZWave.Commands.AlarmReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.AlarmReport

  describe "creates the command and validates params" do
    test "v1" do
      {:ok, command} = AlarmReport.new(type: 0x16, level: 0x17)

      assert Command.param!(command, :type) == 0x16
      assert Command.param!(command, :level) == 0x17
    end

    test "v2 with defaults" do
      {:ok, command} =
        AlarmReport.new(
          type: 0x10,
          level: 0x25,
          zwave_status: :enabled,
          zwave_event: :manual_unlock_operation,
          zwave_type: :access_control
        )

      assert Command.param!(command, :zwave_event) == :manual_unlock_operation
      assert Command.param!(command, :zwave_type) == :access_control
      assert Command.param!(command, :zwave_status) == :enabled
      assert Command.param!(command, :type) == 0x10
      assert Command.param!(command, :level) == 0x25
      assert Command.param!(command, :event_parameters) == []
      assert Command.param!(command, :zensor_net_node_id) == 0
    end

    test "v2 override defaults" do
      {:ok, command} =
        AlarmReport.new(
          type: 0x10,
          level: 0x25,
          zwave_status: :disabled,
          zwave_event: :manual_unlock_operation,
          zwave_type: :access_control,
          zensor_net_node_id: 0x05,
          event_parameters: [0x02, 0x03]
        )

      assert Command.param!(command, :zwave_event) == :manual_unlock_operation
      assert Command.param!(command, :zwave_type) == :access_control
      assert Command.param!(command, :zwave_status) == :disabled
      assert Command.param!(command, :type) == 0x10
      assert Command.param!(command, :level) == 0x25
      assert Command.param!(command, :event_parameters) == [0x02, 0x03]
      assert Command.param!(command, :zensor_net_node_id) == 0x05
    end
  end

  describe "encodes params correctly" do
    test "v1" do
      {:ok, command} = AlarmReport.new(type: 0x16, level: 0x17)

      assert <<0x16, 0x17>> == AlarmReport.encode_params(command)
    end

    test "v2 with no event params" do
      {:ok, command} =
        AlarmReport.new(
          type: 0x10,
          level: 0x25,
          zwave_status: :disabled,
          zwave_event: :manual_unlock_operation,
          zwave_type: :access_control
        )

      assert <<0x10, 0x25, 0x00, 0x00, 0x06, 0x02, 0x00>> ==
               AlarmReport.encode_params(command)
    end

    test "v2 with event params" do
      {:ok, command} =
        AlarmReport.new(
          type: 0x10,
          level: 0x25,
          zwave_status: :disabled,
          zwave_event: :keypad_unlock_operation,
          zwave_type: :access_control,
          event_parameters: [user_id: 251, user_id_status: :occupied, user_code: ""]
        )

      assert <<0x10, 0x25, 0x00, 0x00, 0x06, 0x06, 0x04, 0x63, 0x03, 0xFB, 0x01>> ==
               AlarmReport.encode_params(command)
    end

    test "v8 with sequence number" do
      {:ok, command} =
        AlarmReport.new(
          type: 0x10,
          level: 0x25,
          zwave_status: :disabled,
          zwave_event: :keypad_unlock_operation,
          zwave_type: :access_control,
          event_parameters: [user_id: 251, user_id_status: :occupied, user_code: ""],
          sequence_number: 9
        )

      assert <<0x10, 0x25, 0x00, 0x00, 0x06, 0x06, 0x01::1, 0x00::2, 0x04::5, 0x63, 0x03, 0xFB,
               0x01,
               0x09>> ==
               AlarmReport.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1" do
      binary = <<0x05, 0x10>>
      expected_params = [type: 0x05, level: 0x10]

      assert {:ok, expected_params} == AlarmReport.decode_params(binary)
    end

    test "v2 with no event params" do
      binary = <<0x10, 0x25, 0x00, 0x00, 0x06, 0x02, 0x00>>

      {:ok, params} = AlarmReport.decode_params(binary)

      assert Keyword.fetch!(params, :type) == 0x10
      assert Keyword.fetch!(params, :level) == 0x25
      assert Keyword.fetch!(params, :zwave_status) == :disabled
      assert Keyword.fetch!(params, :zensor_net_node_id) == 0x00
      assert Keyword.fetch!(params, :zwave_event) == :manual_unlock_operation
      assert Keyword.fetch!(params, :zwave_type) == :access_control
      assert Keyword.fetch!(params, :event_parameters) == []
    end

    test "v2 no parameters or parameter length" do
      binary = <<0x10, 0x25, 0x00, 0x00, 0x06, 0x06>>

      {:ok, params} = AlarmReport.decode_params(binary)

      assert Keyword.fetch!(params, :type) == 0x10
      assert Keyword.fetch!(params, :level) == 0x25
      assert Keyword.fetch!(params, :zwave_status) == :disabled
      assert Keyword.fetch!(params, :zensor_net_node_id) == 0x00
      assert Keyword.fetch!(params, :zwave_event) == :keypad_unlock_operation
      assert Keyword.fetch!(params, :zwave_type) == :access_control
    end

    test "v2 with event params" do
      binary = <<0x10, 0x25, 0x00, 0x00, 0x06, 0x06, 0x04, 0x63, 0x03, 0xFB, 0x01>>

      {:ok, params} = AlarmReport.decode_params(binary)

      assert Keyword.fetch!(params, :type) == 0x10
      assert Keyword.fetch!(params, :level) == 0x25
      assert Keyword.fetch!(params, :zwave_status) == :disabled
      assert Keyword.fetch!(params, :zensor_net_node_id) == 0x00
      assert Keyword.fetch!(params, :zwave_event) == :keypad_unlock_operation
      assert Keyword.fetch!(params, :zwave_type) == :access_control

      assert Keyword.fetch!(params, :event_parameters) == [
               user_id: 251,
               user_id_status: :occupied,
               user_code: ""
             ]
    end

    test "v8 with sequence number" do
      binary =
        <<0x10, 0x25, 0x00, 0x00, 0x06, 0x06, 0x01::1, 0x00::2, 0x04::5, 0x63, 0x03, 0xFB, 0x01,
          0x09>>

      {:ok, params} = AlarmReport.decode_params(binary)

      assert Keyword.fetch!(params, :type) == 0x10
      assert Keyword.fetch!(params, :level) == 0x25
      assert Keyword.fetch!(params, :zwave_status) == :disabled
      assert Keyword.fetch!(params, :zensor_net_node_id) == 0x00
      assert Keyword.fetch!(params, :zwave_event) == :keypad_unlock_operation
      assert Keyword.fetch!(params, :zwave_type) == :access_control

      assert Keyword.fetch!(params, :event_parameters) == [
               user_id: 251,
               user_id_status: :occupied,
               user_code: ""
             ]

      assert Keyword.fetch!(params, :sequence_number) == 9
    end
  end
end
