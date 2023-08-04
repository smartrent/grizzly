defmodule Grizzly.ZWave.Commands.NodeAddDSKReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeAddDSKReport

  test "create a new NodeAddDSKReport" do
    assert {:ok, command} =
             NodeAddDSKReport.new(
               seq_number: 0x01,
               input_dsk_length: 1,
               dsk: "50285-18819-09924-30691-15973-33711-04005-03623"
             )

    assert 1 == command.params[:seq_number]
    assert 1 == command.params[:input_dsk_length]
    assert "50285-18819-09924-30691-15973-33711-04005-03623" == command.params[:dsk]
  end
end
