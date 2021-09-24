defmodule Grizzly.ZWave.Commands.FailedNodeListReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FailedNodeListReport

  test "creates the command and validates params" do
    params = [seq_number: 10, node_ids: [1, 2, 3, 9]]
    {:ok, _command} = FailedNodeListReport.new(params)
  end

  test "encodes params correctly" do
    params = [seq_number: 10, node_ids: [1, 2, 3, 9, 256]]
    {:ok, command} = FailedNodeListReport.new(params)

    expected_binary =
      <<0x0A, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 1>>

    assert expected_binary == FailedNodeListReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary =
      <<0x0A, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0>>

    {:ok, params} = FailedNodeListReport.decode_params(params_binary)
    assert Keyword.get(params, :seq_number) == 10
    assert Keyword.get(params, :node_ids) == [1, 2, 3, 9]
  end
end
