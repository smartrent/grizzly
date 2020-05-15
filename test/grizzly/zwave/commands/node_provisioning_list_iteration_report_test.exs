defmodule Grizzly.ZWave.Commands.NodeProvisioningListIterationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeProvisioningListIterationReport

  test "creates the command and validates params" do
    params = [
      seq_number: 0x01,
      remaining_count: 2,
      dsk: "50285-18819-09924-30691-15973-33711-04005-03623",
      meta_extensions: []
    ]

    {:ok, _command} = NodeProvisioningListIterationReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      seq_number: 0x01,
      remaining_count: 2,
      dsk: "50285-18819-09924-30691-15973-33711-04005-03623",
      meta_extensions: []
    ]

    {:ok, command} = NodeProvisioningListIterationReport.new(params)

    expected_binary =
      <<0x01, 0x02, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14,
        39>>

    assert expected_binary == NodeProvisioningListIterationReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x01, 0x02, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14,
        39>>

    {:ok, params} = NodeProvisioningListIterationReport.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 1
    assert Keyword.get(params, :remaining_count) == 2
    assert Keyword.get(params, :dsk) == "50285-18819-09924-30691-15973-33711-04005-03623"
    assert Keyword.get(params, :meta_extensions) == []
  end
end
