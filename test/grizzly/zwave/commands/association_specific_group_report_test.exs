defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationSpecificGroupReport

  test "creates the command and validates params" do
    params = [group: 5]
    {:ok, _command} = AssociationSpecificGroupReport.new(params)
  end

  test "encodes params correctly" do
    params = [group: 5]
    {:ok, command} = AssociationSpecificGroupReport.new(params)
    expected_binary = <<0x05>>
    assert AssociationSpecificGroupReport.encode_params(command) == expected_binary
  end

  test "decodes params correctly" do
    binary_params = <<0x05>>
    {:ok, params} = AssociationSpecificGroupReport.decode_params(binary_params)
    assert Keyword.get(params, :group) == 5
  end
end
