defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationSpecificGroupReport

  test "creates the command and validates params" do
    params = [group: 5]
    {:ok, _command} = Commands.create(:association_specific_group_report, params)
  end

  test "encodes params correctly" do
    params = [group: 5]
    {:ok, command} = Commands.create(:association_specific_group_report, params)
    expected_binary = <<0x05>>
    assert AssociationSpecificGroupReport.encode_params(nil, command) == expected_binary
  end

  test "decodes params correctly" do
    binary_params = <<0x05>>
    {:ok, params} = AssociationSpecificGroupReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :group) == 5
  end
end
