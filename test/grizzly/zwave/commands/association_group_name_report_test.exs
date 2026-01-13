defmodule Grizzly.ZWave.Commands.AssociationNameReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupNameReport

  test "creates the command and validates params" do
    params = [group_id: 2, name: "some_name"]
    {:ok, _command} = Commands.create(:association_group_name_report, params)
  end

  test "encodes params correctly" do
    params = [group_id: 2, name: "some_name"]
    {:ok, command} = Commands.create(:association_group_name_report, params)
    expected_binary = <<0x02, 0x09>> <> "some_name"
    assert expected_binary == AssociationGroupNameReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x09>> <> "some_name"
    {:ok, params} = AssociationGroupNameReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :group_id) == 2
    assert Keyword.get(params, :name) == "some_name"
  end

  test "decodes params correctly even if extra bytes" do
    binary_params = <<0x02, 0x09>> <> "some_name" <> <<0x00>>
    {:ok, params} = AssociationGroupNameReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :group_id) == 2
    assert Keyword.get(params, :name) == "some_name"
  end
end
