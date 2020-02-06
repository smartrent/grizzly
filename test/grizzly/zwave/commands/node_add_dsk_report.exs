defmodule Grizzly.ZWave.Commands.NodeAddDSKReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.NodeAddDSKReport
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  test "create a new NodeAddDSKReport" do
    expected_command = %Command{
      name: :node_add_dsk_report,
      command_class_name: :network_management_inclusion,
      command_byte: 0x13,
      command_class_byte: 0x34,
      params: [
        seq_number: 0x01,
        input_dsk_length: 1,
        dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
      ],
      handler: AckResponse,
      impl: NodeAddDSKReport
    }

    assert {:ok, expected_command} ==
             NodeAddDSKReport.new(
               seq_number: 0x01,
               input_dsk_length: 1,
               dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
             )
  end
end
