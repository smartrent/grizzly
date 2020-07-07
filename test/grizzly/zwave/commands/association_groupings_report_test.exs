defmodule Grizzly.ZWave.Commands.AssociationGroupingsReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationGroupingsReport

  test "creates the command and validates params" do
    params = [supported_groupings: 5]
    {:ok, _command} = AssociationGroupingsReport.new(params)
  end

  test "encodes params correctly" do
    params = [supported_groupings: 5]
    {:ok, command} = AssociationGroupingsReport.new(params)
    expected_binary = <<0x05>>
    assert AssociationGroupingsReport.encode_params(command) == expected_binary
  end

  test "decodes params correctly" do
    binary_params = <<0x05>>
    {:ok, params} = AssociationGroupingsReport.decode_params(binary_params)
    assert Keyword.get(params, :supported_groupings) == 5
  end
end
