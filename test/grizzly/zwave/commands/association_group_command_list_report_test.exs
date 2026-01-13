defmodule Grizzly.ZWave.Commands.AssociationGroupCommandListReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupCommandListReport

  test "creates the command and validates params" do
    params = [group_id: 2, commands: [:basic_set, :basic_get, :battery_get]]
    {:ok, _command} = Commands.create(:association_group_command_list_report, params)
  end

  test "encodes params correctly" do
    params = [group_id: 2, commands: [:basic_set, :basic_get, :battery_get]]
    {:ok, command} = Commands.create(:association_group_command_list_report, params)
    expected_binary = <<0x02, 0x06, 0x20, 0x01, 0x20, 0x02, 0x80, 0x02>>
    assert expected_binary == AssociationGroupCommandListReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x06, 0x20, 0x01, 0x20, 0x02, 0x80, 0x02>>
    {:ok, params} = AssociationGroupCommandListReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :group_id) == 2
    commands = Keyword.get(params, :commands)
    assert Enum.count(commands) == 3
    assert Enum.all?([:basic_set, :basic_get, :battery_get], &(&1 in commands)) == true
  end

  test "decodes params correctly in spite of extra byte" do
    binary_params = <<0x02, 0x06, 0x20, 0x01, 0x20, 0x02, 0x80, 0x02, 0x00>>
    {:ok, params} = AssociationGroupCommandListReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :group_id) == 2
    commands = Keyword.get(params, :commands)
    assert Enum.count(commands) == 3
    assert Enum.all?([:basic_set, :basic_get, :battery_get], &(&1 in commands)) == true
  end
end
